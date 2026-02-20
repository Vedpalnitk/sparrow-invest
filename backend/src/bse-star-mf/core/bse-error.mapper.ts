import { Injectable, BadRequestException, UnauthorizedException, InternalServerErrorException, ServiceUnavailableException } from '@nestjs/common'
import { getBseErrorMessage } from './constants/error-codes'

export interface BseApiResult {
  success: boolean
  code: string
  message: string
  data?: any
}

@Injectable()
export class BseErrorMapper {
  parseResponse(responseCode: string, responseMessage?: string): BseApiResult {
    const code = responseCode?.trim()
    const success = code === '100'

    return {
      success,
      code,
      message: responseMessage || getBseErrorMessage(code),
      data: undefined,
    }
  }

  throwIfError(result: BseApiResult): void {
    if (result.success) return

    const code = result.code

    // Auth errors
    if (['101', '102', '103', '104', '105'].includes(code)) {
      throw new UnauthorizedException(`BSE authentication failed: ${result.message}`)
    }

    // Client/registration errors
    if (['106', '107', '127', '128', '129', '130'].includes(code)) {
      throw new BadRequestException(`BSE client error: ${result.message}`)
    }

    // Order/scheme errors
    if (['108', '109', '110', '111', '112', '113', '114', '115', '116', '117', '118', '119'].includes(code)) {
      throw new BadRequestException(`BSE order error: ${result.message}`)
    }

    // Mandate errors
    if (['120', '121', '122'].includes(code)) {
      throw new BadRequestException(`BSE mandate error: ${result.message}`)
    }

    // Payment errors
    if (['123', '124', '125', '126'].includes(code)) {
      throw new BadRequestException(`BSE payment error: ${result.message}`)
    }

    // System errors
    if (['201', '202'].includes(code)) {
      throw new ServiceUnavailableException(`BSE system error: ${result.message}`)
    }

    throw new InternalServerErrorException(`BSE error (${code}): ${result.message}`)
  }

  /**
   * Parse pipe-separated BSE response into structured result
   * Most BSE SOAP responses return: "responseCode|message|data..."
   */
  parsePipeResponse(response: string): BseApiResult {
    const parts = response.split('|')
    const code = parts[0]?.trim()

    return {
      success: code === '100',
      code,
      message: parts[1] || getBseErrorMessage(code),
      data: parts.slice(2),
    }
  }
}
