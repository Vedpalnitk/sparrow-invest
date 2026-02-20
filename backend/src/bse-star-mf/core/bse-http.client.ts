import { Injectable, Logger } from '@nestjs/common'
import { ConfigService } from '@nestjs/config'
import { PrismaService } from '../../prisma/prisma.service'
import { BseSoapBuilder } from './bse-soap.builder'
import { BSE_TIMEOUTS } from './bse-config'

export interface BseHttpResponse {
  statusCode: number
  body: string
  parsed?: any
}

@Injectable()
export class BseHttpClient {
  private readonly logger = new Logger(BseHttpClient.name)
  private readonly baseUrl: string

  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
    private soapBuilder: BseSoapBuilder,
  ) {
    this.baseUrl = this.config.get<string>('bse.baseUrl') || 'https://bsestarmfdemo.bseindia.com'
  }

  async soapRequest(
    endpoint: string,
    soapAction: string,
    body: string,
    advisorId: string,
    apiName: string,
    timeoutMs = BSE_TIMEOUTS.DEFAULT,
  ): Promise<BseHttpResponse> {
    const url = `${this.baseUrl}${endpoint}`
    const envelope = this.soapBuilder.buildEnvelope(soapAction, body)
    const startTime = Date.now()

    try {
      const controller = new AbortController()
      const timeout = setTimeout(() => controller.abort(), timeoutMs)

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
          SOAPAction: soapAction,
        },
        body: envelope,
        signal: controller.signal,
      })

      clearTimeout(timeout)
      const responseBody = await response.text()
      const latencyMs = Date.now() - startTime

      await this.logApiCall(advisorId, apiName, url, 'POST', envelope, responseBody, response.status, latencyMs)

      return {
        statusCode: response.status,
        body: responseBody,
      }
    } catch (error) {
      const latencyMs = Date.now() - startTime
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      await this.logApiCall(advisorId, apiName, url, 'POST', null, null, 0, latencyMs, errorMessage)
      throw error
    }
  }

  async jsonRequest(
    endpoint: string,
    method: 'GET' | 'POST',
    body: any,
    advisorId: string,
    apiName: string,
    headers: Record<string, string> = {},
    timeoutMs = BSE_TIMEOUTS.DEFAULT,
  ): Promise<BseHttpResponse> {
    const url = `${this.baseUrl}${endpoint}`
    const startTime = Date.now()

    try {
      const controller = new AbortController()
      const timeout = setTimeout(() => controller.abort(), timeoutMs)

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
        body: method === 'POST' ? JSON.stringify(body) : undefined,
        signal: controller.signal,
      })

      clearTimeout(timeout)
      const responseBody = await response.text()
      const latencyMs = Date.now() - startTime

      let parsed: any
      try {
        parsed = JSON.parse(responseBody)
      } catch {
        parsed = undefined
      }

      await this.logApiCall(advisorId, apiName, url, method, body, parsed || responseBody, response.status, latencyMs)

      return {
        statusCode: response.status,
        body: responseBody,
        parsed,
      }
    } catch (error) {
      const latencyMs = Date.now() - startTime
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      await this.logApiCall(advisorId, apiName, url, method, body, null, 0, latencyMs, errorMessage)
      throw error
    }
  }

  private async logApiCall(
    advisorId: string,
    apiName: string,
    endpoint: string,
    method: string,
    requestData: any,
    responseData: any,
    statusCode: number,
    latencyMs: number,
    errorMessage?: string,
  ) {
    try {
      // Sanitize request data - remove passwords, tokens, PAN
      const sanitizedRequest = this.sanitize(requestData)
      const sanitizedResponse = this.sanitize(responseData)

      await this.prisma.bseApiLog.create({
        data: {
          advisorId,
          apiName,
          endpoint,
          method,
          requestData: sanitizedRequest,
          responseData: sanitizedResponse,
          statusCode,
          latencyMs,
          errorMessage,
        },
      })
    } catch (err) {
      this.logger.warn('Failed to log BSE API call', err)
    }
  }

  private sanitize(data: any): any {
    if (!data) return null
    if (typeof data === 'string') {
      // Mask passwords and tokens in SOAP XML
      return data
        .replace(/<Password>[^<]*<\/Password>/gi, '<Password>***</Password>')
        .replace(/<PassKey>[^<]*<\/PassKey>/gi, '<PassKey>***</PassKey>')
        .replace(/\b[A-Z]{5}\d{4}[A-Z]\b/g, '***PAN***')
    }
    if (typeof data === 'object') {
      const sanitized = { ...data }
      const sensitiveKeys = ['password', 'passKey', 'Password', 'PassKey', 'token', 'Token', 'pan', 'PAN']
      for (const key of sensitiveKeys) {
        if (key in sanitized) {
          sanitized[key] = '***'
        }
      }
      return sanitized
    }
    return data
  }
}
