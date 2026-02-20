import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Logger } from '@nestjs/common'
import { Observable, of } from 'rxjs'
import { ConfigService } from '@nestjs/config'

@Injectable()
export class BseMockInterceptor implements NestInterceptor {
  private readonly logger = new Logger(BseMockInterceptor.name)
  private readonly isMockMode: boolean

  constructor(private config: ConfigService) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
    if (this.isMockMode) {
      this.logger.warn('BSE Mock Mode is ENABLED - no real BSE API calls will be made')
    }
  }

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    // Only intercept if in mock mode (actual mock responses are handled at service level)
    return next.handle()
  }

  get isActive(): boolean {
    return this.isMockMode
  }
}
