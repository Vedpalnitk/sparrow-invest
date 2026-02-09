import { Controller, Get, Put, Body, Query, Request } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { UpdatePreferencesDto, NotificationLogsQueryDto } from './dto/notification-preference.dto';

@Controller('notifications')
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Get('preferences')
  async getPreferences(@Request() req: any) {
    return this.notificationsService.getPreferences(req.user.userId);
  }

  @Put('preferences')
  async updatePreferences(@Request() req: any, @Body() dto: UpdatePreferencesDto) {
    return this.notificationsService.updatePreferences(req.user.userId, dto.updates);
  }

  @Get('logs')
  async getLogs(@Request() req: any, @Query() query: NotificationLogsQueryDto) {
    const limit = parseInt(query.limit || '50', 10);
    const offset = parseInt(query.offset || '0', 10);
    return this.notificationsService.getLogs(req.user.userId, limit, offset);
  }
}
