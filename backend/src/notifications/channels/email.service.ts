import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor(private configService: ConfigService) {
    const host = this.configService.get<string>('email.host');
    const user = this.configService.get<string>('email.user');

    if (host && user) {
      this.transporter = nodemailer.createTransport({
        host,
        port: this.configService.get<number>('email.port'),
        secure: false,
        auth: {
          user,
          pass: this.configService.get<string>('email.pass'),
        },
      });
      this.logger.log('Email transport configured');
    } else {
      this.logger.warn('Email transport not configured — SMTP credentials missing');
    }
  }

  async send(to: string, subject: string, body: string): Promise<{ success: boolean; messageId?: string; error?: string }> {
    if (!this.transporter) {
      this.logger.warn('Email send skipped — transport not configured');
      return { success: false, error: 'Email transport not configured' };
    }

    try {
      const info = await this.transporter.sendMail({
        from: this.configService.get<string>('email.from'),
        to,
        subject,
        html: body,
      });

      this.logger.log(`Email sent to ${to}: ${info.messageId}`);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      this.logger.error(`Email send failed: ${error.message}`);
      return { success: false, error: error.message };
    }
  }
}
