import { Injectable } from '@nestjs/common'
import { BseSessionManager } from '../core/bse-session.manager'
import { BseSessionType } from '@prisma/client'

@Injectable()
export class BseAuthService {
  constructor(private sessionManager: BseSessionManager) {}

  async getOrderEntryToken(userId: string): Promise<string> {
    return this.sessionManager.getSessionToken(userId, BseSessionType.ORDER_ENTRY)
  }

  async getAdditionalServicesToken(userId: string): Promise<string> {
    return this.sessionManager.getSessionToken(userId, BseSessionType.ADDITIONAL_SERVICES)
  }

  async getFileUploadToken(userId: string): Promise<string> {
    return this.sessionManager.getSessionToken(userId, BseSessionType.FILE_UPLOAD)
  }

  async getMandateStatusToken(userId: string): Promise<string> {
    return this.sessionManager.getSessionToken(userId, BseSessionType.MANDATE_STATUS)
  }

  async getChildOrderToken(userId: string): Promise<string> {
    return this.sessionManager.getSessionToken(userId, BseSessionType.CHILD_ORDER)
  }

  async invalidateAllTokens(userId: string): Promise<void> {
    await this.sessionManager.invalidateAllSessions(userId)
  }
}
