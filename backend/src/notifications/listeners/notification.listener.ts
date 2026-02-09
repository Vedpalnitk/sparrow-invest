import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationsService } from '../notifications.service';

@Injectable()
export class NotificationListener {
  private readonly logger = new Logger(NotificationListener.name);

  constructor(private notificationsService: NotificationsService) {}

  @OnEvent('notification.**')
  async handleNotification(payload: { userId: string; category: string; title: string; body: string; metadata?: Record<string, any> }) {
    this.logger.log(`Notification event for user ${payload.userId}, category ${payload.category}`);
    await this.notificationsService.dispatch(payload);
  }
}
