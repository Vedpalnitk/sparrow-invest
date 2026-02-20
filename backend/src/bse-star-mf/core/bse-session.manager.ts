import { Injectable, Logger } from '@nestjs/common'
import { PrismaService } from '../../prisma/prisma.service'
import { BseHttpClient } from './bse-http.client'
import { BseSoapBuilder } from './bse-soap.builder'
import { BseCryptoService } from './bse-crypto.service'
import { BSE_ENDPOINTS, BSE_SESSION_TTL, BSE_SOAP_ACTIONS } from './bse-config'
import { BseSessionType } from '@prisma/client'
import { XMLParser } from 'fast-xml-parser'

@Injectable()
export class BseSessionManager {
  private readonly logger = new Logger(BseSessionManager.name)
  private readonly xmlParser = new XMLParser()
  // In-flight dedup: prevents concurrent token refresh for same user+type
  private readonly inflightRequests = new Map<string, Promise<string>>()

  constructor(
    private prisma: PrismaService,
    private httpClient: BseHttpClient,
    private soapBuilder: BseSoapBuilder,
    private crypto: BseCryptoService,
  ) {}

  async getSessionToken(userId: string, sessionType: BseSessionType): Promise<string> {
    const ttl = BSE_SESSION_TTL[sessionType]

    // Per-request tokens (no caching)
    if (ttl === 0) {
      return this.fetchNewToken(userId, sessionType)
    }

    // Check cached token
    const cached = await this.prisma.bseSessionToken.findUnique({
      where: { userId_sessionType: { userId, sessionType } },
    })

    if (cached && cached.expiresAt > new Date()) {
      return cached.token
    }

    // Dedup concurrent requests
    const dedupKey = `${userId}:${sessionType}`
    const inflight = this.inflightRequests.get(dedupKey)
    if (inflight) {
      return inflight
    }

    const promise = this.fetchAndCacheToken(userId, sessionType, ttl)
    this.inflightRequests.set(dedupKey, promise)

    try {
      return await promise
    } finally {
      this.inflightRequests.delete(dedupKey)
    }
  }

  private async fetchAndCacheToken(
    userId: string,
    sessionType: BseSessionType,
    ttl: number,
  ): Promise<string> {
    const token = await this.fetchNewToken(userId, sessionType)

    const expiresAt = new Date(Date.now() + ttl - 60000) // 1min safety buffer

    await this.prisma.bseSessionToken.upsert({
      where: { userId_sessionType: { userId, sessionType } },
      update: { token, expiresAt },
      create: { userId, sessionType, token, expiresAt },
    })

    return token
  }

  private async fetchNewToken(userId: string, sessionType: BseSessionType): Promise<string> {
    const credential = await this.prisma.bsePartnerCredential.findUnique({
      where: { userId },
    })

    if (!credential) {
      throw new Error('BSE credentials not configured for this user')
    }

    const password = this.crypto.decrypt(credential.passwordEnc, credential.ivPassword)
    const passKey = this.crypto.decrypt(credential.passKeyEnc, credential.ivPassKey)

    const endpoint = sessionType === 'ORDER_ENTRY'
      ? BSE_ENDPOINTS.ORDER_PASSWORD
      : BSE_ENDPOINTS.ADDITIONAL_PASSWORD

    const soapAction = sessionType === 'ORDER_ENTRY'
      ? BSE_SOAP_ACTIONS.GET_PASSWORD
      : BSE_SOAP_ACTIONS.ADDITIONAL_PASSWORD

    const body = this.soapBuilder.buildGetPasswordBody(
      credential.userIdBse,
      credential.memberId,
      password,
      passKey,
    )

    const response = await this.httpClient.soapRequest(
      endpoint,
      soapAction,
      body,
      userId,
      'getPassword',
    )

    return this.parsePasswordResponse(response.body)
  }

  private parsePasswordResponse(xml: string): string {
    const parsed = this.xmlParser.parse(xml)

    // Navigate SOAP response structure
    const envelope = parsed['soap:Envelope'] || parsed['s:Envelope']
    const body = envelope?.['soap:Body'] || envelope?.['s:Body']
    const result = body?.getPasswordResponse?.getPasswordResult

    if (!result) {
      throw new Error('Failed to parse BSE password response')
    }

    // BSE returns "100|token_value" on success
    const parts = String(result).split('|')
    if (parts[0] === '100' && parts[1]) {
      return parts[1]
    }

    throw new Error(`BSE getPassword failed: ${result}`)
  }

  async invalidateSession(userId: string, sessionType: BseSessionType): Promise<void> {
    await this.prisma.bseSessionToken.deleteMany({
      where: { userId, sessionType },
    })
  }

  async invalidateAllSessions(userId: string): Promise<void> {
    await this.prisma.bseSessionToken.deleteMany({
      where: { userId },
    })
  }
}
