import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common'
import { PrismaService } from '../../prisma/prisma.service'
import { BseCryptoService } from '../core/bse-crypto.service'
import { BseAuthService } from '../auth/bse-auth.service'

export class SetCredentialsDto {
  memberId: string
  userIdBse: string
  password: string
  arn: string
  euin?: string
  passKey: string
}

export interface CredentialStatusResponse {
  isConfigured: boolean
  memberId?: string
  userIdBse?: string
  arn?: string
  euin?: string
  isActive?: boolean
  lastTestedAt?: Date | null
  testStatus?: string | null
}

@Injectable()
export class BseCredentialsService {
  constructor(
    private prisma: PrismaService,
    private crypto: BseCryptoService,
    private authService: BseAuthService,
  ) {}

  async getStatus(userId: string): Promise<CredentialStatusResponse> {
    const credential = await this.prisma.bsePartnerCredential.findUnique({
      where: { userId },
    })

    if (!credential) {
      return { isConfigured: false }
    }

    return {
      isConfigured: true,
      memberId: credential.memberId,
      userIdBse: credential.userIdBse,
      arn: credential.arn,
      euin: credential.euin || undefined,
      isActive: credential.isActive,
      lastTestedAt: credential.lastTestedAt,
      testStatus: credential.testStatus,
    }
  }

  async setCredentials(userId: string, dto: SetCredentialsDto): Promise<CredentialStatusResponse> {
    const { encrypted: passwordEnc, iv: ivPassword } = this.crypto.encrypt(dto.password)
    const { encrypted: passKeyEnc, iv: ivPassKey } = this.crypto.encrypt(dto.passKey)
    // member ID also encrypted for storage but we store it in plain for lookups
    const { iv: ivMemberId } = this.crypto.encrypt(dto.memberId)

    const credential = await this.prisma.bsePartnerCredential.upsert({
      where: { userId },
      update: {
        memberId: dto.memberId,
        userIdBse: dto.userIdBse,
        passwordEnc,
        arn: dto.arn,
        euin: dto.euin || null,
        passKeyEnc,
        ivMemberId,
        ivPassword,
        ivPassKey,
        isActive: true,
        testStatus: null,
        lastTestedAt: null,
      },
      create: {
        userId,
        memberId: dto.memberId,
        userIdBse: dto.userIdBse,
        passwordEnc,
        arn: dto.arn,
        euin: dto.euin || null,
        passKeyEnc,
        ivMemberId,
        ivPassword,
        ivPassKey,
      },
    })

    // Invalidate any cached sessions
    await this.authService.invalidateAllTokens(userId)

    return {
      isConfigured: true,
      memberId: credential.memberId,
      userIdBse: credential.userIdBse,
      arn: credential.arn,
      euin: credential.euin || undefined,
      isActive: credential.isActive,
      lastTestedAt: credential.lastTestedAt,
      testStatus: credential.testStatus,
    }
  }

  async testConnection(userId: string): Promise<{ success: boolean; message: string }> {
    const credential = await this.prisma.bsePartnerCredential.findUnique({
      where: { userId },
    })

    if (!credential) {
      throw new NotFoundException('BSE credentials not configured')
    }

    try {
      await this.authService.getOrderEntryToken(userId)

      await this.prisma.bsePartnerCredential.update({
        where: { userId },
        data: {
          lastTestedAt: new Date(),
          testStatus: 'SUCCESS',
        },
      })

      return { success: true, message: 'BSE connection successful' }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Connection failed'

      await this.prisma.bsePartnerCredential.update({
        where: { userId },
        data: {
          lastTestedAt: new Date(),
          testStatus: `FAILED: ${errorMessage}`,
        },
      })

      return { success: false, message: errorMessage }
    }
  }

  async getDecryptedCredentials(userId: string) {
    const credential = await this.prisma.bsePartnerCredential.findUnique({
      where: { userId },
    })

    if (!credential) {
      throw new NotFoundException('BSE credentials not configured')
    }

    if (!credential.isActive) {
      throw new BadRequestException('BSE credentials are inactive')
    }

    return {
      memberId: credential.memberId,
      userIdBse: credential.userIdBse,
      password: this.crypto.decrypt(credential.passwordEnc, credential.ivPassword),
      arn: credential.arn,
      euin: credential.euin,
      passKey: this.crypto.decrypt(credential.passKeyEnc, credential.ivPassKey),
    }
  }
}
