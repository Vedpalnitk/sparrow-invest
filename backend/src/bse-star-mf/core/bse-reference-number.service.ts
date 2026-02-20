import { Injectable } from '@nestjs/common'
import { PrismaService } from '../../prisma/prisma.service'

@Injectable()
export class BseReferenceNumberService {
  constructor(private prisma: PrismaService) {}

  /**
   * Generate unique BSE transaction reference number
   * Format: YYYYMMDD<memberId>NNNNNN
   * where NNNNNN is a zero-padded sequential number
   */
  async generate(memberId: string): Promise<string> {
    const today = new Date()
    const datePrefix = today.toISOString().slice(0, 10).replace(/-/g, '')
    const prefix = `${datePrefix}${memberId}`

    // Count existing orders with this prefix today to get sequence
    const count = await this.prisma.bseOrder.count({
      where: {
        referenceNumber: {
          startsWith: prefix,
        },
      },
    })

    const sequence = String(count + 1).padStart(6, '0')
    return `${prefix}${sequence}`
  }
}
