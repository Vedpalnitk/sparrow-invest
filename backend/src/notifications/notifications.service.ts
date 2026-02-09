import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { EmailService } from './channels/email.service';
import { WhatsAppService } from './channels/whatsapp.service';
import { NotificationPayload } from './events/notification.events';

const ALL_CATEGORIES = [
  'TRADE_ALERTS',
  'SIP_REMINDERS',
  'CLIENT_REQUESTS',
  'MARKET_UPDATES',
  'DAILY_DIGEST',
  'PORTFOLIO_ALERTS',
  'KYC_ALERTS',
] as const;

const ALL_CHANNELS = ['PUSH', 'EMAIL', 'WHATSAPP'] as const;

// Default enabled state per category/channel
const DEFAULT_ENABLED: Record<string, Record<string, boolean>> = {
  TRADE_ALERTS: { PUSH: true, EMAIL: true, WHATSAPP: false },
  SIP_REMINDERS: { PUSH: true, EMAIL: true, WHATSAPP: false },
  CLIENT_REQUESTS: { PUSH: true, EMAIL: true, WHATSAPP: false },
  MARKET_UPDATES: { PUSH: false, EMAIL: false, WHATSAPP: false },
  DAILY_DIGEST: { PUSH: false, EMAIL: true, WHATSAPP: false },
  PORTFOLIO_ALERTS: { PUSH: true, EMAIL: false, WHATSAPP: false },
  KYC_ALERTS: { PUSH: true, EMAIL: true, WHATSAPP: false },
};

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private prisma: PrismaService,
    private emailService: EmailService,
    private whatsAppService: WhatsAppService,
  ) {}

  /**
   * Get all preferences for a user, seeding defaults if first time.
   */
  async getPreferences(userId: string) {
    let prefs = await this.prisma.notificationPreference.findMany({
      where: { userId },
    });

    // Seed defaults on first access
    if (prefs.length === 0) {
      const data: Prisma.NotificationPreferenceCreateManyInput[] = [];
      for (const category of ALL_CATEGORIES) {
        for (const channel of ALL_CHANNELS) {
          data.push({
            userId,
            category: category as any,
            channel: channel as any,
            enabled: DEFAULT_ENABLED[category]?.[channel] ?? false,
          });
        }
      }

      await this.prisma.notificationPreference.createMany({ data });
      prefs = await this.prisma.notificationPreference.findMany({ where: { userId } });
    }

    // Group by category
    const grouped: Record<string, Record<string, boolean>> = {};
    for (const pref of prefs) {
      if (!grouped[pref.category]) {
        grouped[pref.category] = {};
      }
      grouped[pref.category][pref.channel] = pref.enabled;
    }

    return grouped;
  }

  /**
   * Bulk update preferences.
   */
  async updatePreferences(userId: string, updates: { category: string; channel: string; enabled: boolean }[]) {
    // Ensure defaults exist first
    await this.getPreferences(userId);

    for (const update of updates) {
      await this.prisma.notificationPreference.updateMany({
        where: {
          userId,
          category: update.category as any,
          channel: update.channel as any,
        },
        data: { enabled: update.enabled },
      });
    }

    return this.getPreferences(userId);
  }

  /**
   * Get notification delivery logs for a user.
   */
  async getLogs(userId: string, limit = 50, offset = 0) {
    const [logs, total] = await Promise.all([
      this.prisma.notificationLog.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
      }),
      this.prisma.notificationLog.count({ where: { userId } }),
    ]);

    return {
      data: logs.map((log) => ({
        id: log.id,
        category: log.category,
        channel: log.channel,
        status: log.status,
        subject: log.subject,
        body: log.body,
        error: log.error,
        sentAt: log.sentAt?.toISOString() || null,
        createdAt: log.createdAt.toISOString(),
      })),
      total,
      limit,
      offset,
    };
  }

  /**
   * Dispatch a notification to all enabled channels for a user/category.
   */
  async dispatch(payload: NotificationPayload) {
    const { userId, category, title, body } = payload;

    // Get user info for delivery
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, phone: true },
    });

    if (!user) {
      this.logger.warn(`Notification dispatch failed — user ${userId} not found`);
      return;
    }

    // Get preferences for this category
    const prefs = await this.prisma.notificationPreference.findMany({
      where: {
        userId,
        category: category as any,
        enabled: true,
      },
    });

    // If no prefs exist yet, don't send
    if (prefs.length === 0) {
      this.logger.debug(`No enabled prefs for user ${userId}, category ${category}`);
      return;
    }

    for (const pref of prefs) {
      await this.sendToChannel(userId, user, pref.channel, category, title, body);
    }
  }

  private async sendToChannel(
    userId: string,
    user: { email: string; phone: string | null },
    channel: string,
    category: string,
    subject: string,
    body: string,
  ) {
    // Create log entry
    const log = await this.prisma.notificationLog.create({
      data: {
        userId,
        category: category as any,
        channel: channel as any,
        status: 'PENDING',
        subject,
        body,
      },
    });

    try {
      let result: { success: boolean; messageId?: string; sid?: string; error?: string };

      switch (channel) {
        case 'EMAIL':
          result = await this.emailService.send(user.email, subject, body);
          break;
        case 'WHATSAPP':
          if (!user.phone) {
            result = { success: false, error: 'No phone number on file' };
            break;
          }
          result = await this.whatsAppService.send(user.phone, `*${subject}*\n\n${body}`);
          break;
        case 'PUSH':
          // Push notifications handled client-side via in-app UserAction system
          result = { success: true };
          break;
        default:
          result = { success: false, error: `Unknown channel: ${channel}` };
      }

      await this.prisma.notificationLog.update({
        where: { id: log.id },
        data: {
          status: result.success ? 'SENT' : 'FAILED',
          externalId: result.messageId || result.sid || null,
          error: result.error || null,
          sentAt: result.success ? new Date() : null,
        },
      });
    } catch (error) {
      await this.prisma.notificationLog.update({
        where: { id: log.id },
        data: {
          status: 'FAILED',
          error: error.message,
        },
      });
    }
  }
}
