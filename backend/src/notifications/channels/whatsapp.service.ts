import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Twilio } from 'twilio';

@Injectable()
export class WhatsAppService {
  private readonly logger = new Logger(WhatsAppService.name);
  private client: Twilio | null = null;
  private from: string;

  constructor(private configService: ConfigService) {
    const accountSid = this.configService.get<string>('whatsapp.accountSid');
    const authToken = this.configService.get<string>('whatsapp.authToken');
    this.from = this.configService.get<string>('whatsapp.from') || 'whatsapp:+14155238886';

    if (accountSid && authToken) {
      this.client = new Twilio(accountSid, authToken);
      this.logger.log('WhatsApp (Twilio) client configured');
    } else {
      this.logger.warn('WhatsApp client not configured — Twilio credentials missing');
    }
  }

  async send(to: string, body: string): Promise<{ success: boolean; sid?: string; error?: string }> {
    if (!this.client) {
      this.logger.warn('WhatsApp send skipped — client not configured');
      return { success: false, error: 'WhatsApp client not configured' };
    }

    try {
      // Ensure 'whatsapp:' prefix
      const toNumber = to.startsWith('whatsapp:') ? to : `whatsapp:${to}`;

      const message = await this.client.messages.create({
        from: this.from,
        to: toNumber,
        body,
      });

      this.logger.log(`WhatsApp sent to ${to}: ${message.sid}`);
      return { success: true, sid: message.sid };
    } catch (error) {
      this.logger.error(`WhatsApp send failed: ${error.message}`);
      return { success: false, error: error.message };
    }
  }
}
