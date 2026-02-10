import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActionType, ActionPriority } from '@prisma/client';
import { CreateActionDto, UpdateActionDto } from './dto/action.dto';

@Injectable()
export class ActionsService {
  constructor(private prisma: PrismaService) {}

  async getUserActions(
    userId: string,
    includeCompleted: boolean = false,
    includeDismissed: boolean = false,
    limit: number = 20,
    offset: number = 0,
  ) {
    const where: any = { userId };

    if (!includeCompleted) {
      where.isCompleted = false;
    }
    if (!includeDismissed) {
      where.isDismissed = false;
    }

    // Exclude expired actions
    where.OR = [{ expiresAt: null }, { expiresAt: { gt: new Date() } }];

    const [actions, total] = await Promise.all([
      this.prisma.userAction.findMany({
        where,
        orderBy: [{ priority: 'desc' }, { dueDate: 'asc' }, { createdAt: 'desc' }],
        take: limit,
        skip: offset,
      }),
      this.prisma.userAction.count({ where }),
    ]);

    return {
      actions: actions.map((action) => this.formatAction(action)),
      total,
      unreadCount: await this.getUnreadCount(userId),
      highPriorityCount: await this.getHighPriorityCount(userId),
    };
  }

  async getActionById(userId: string, actionId: string) {
    const action = await this.prisma.userAction.findFirst({
      where: { id: actionId, userId },
    });

    if (!action) {
      throw new NotFoundException('Action not found');
    }

    return this.formatAction(action);
  }

  async createAction(userId: string, dto: CreateActionDto) {
    const action = await this.prisma.userAction.create({
      data: {
        userId,
        type: dto.type as ActionType,
        priority: (dto.priority as ActionPriority) || ActionPriority.MEDIUM,
        title: dto.title,
        description: dto.description,
        actionUrl: dto.actionUrl,
        referenceId: dto.referenceId,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
      },
    });

    return this.formatAction(action);
  }

  async updateAction(userId: string, actionId: string, dto: UpdateActionDto) {
    const existingAction = await this.prisma.userAction.findFirst({
      where: { id: actionId, userId },
    });

    if (!existingAction) {
      throw new NotFoundException('Action not found');
    }

    const action = await this.prisma.userAction.update({
      where: { id: actionId },
      data: {
        isRead: dto.isRead ?? existingAction.isRead,
        isDismissed: dto.isDismissed ?? existingAction.isDismissed,
        isCompleted: dto.isCompleted ?? existingAction.isCompleted,
      },
    });

    return this.formatAction(action);
  }

  async markAsRead(userId: string, actionId: string) {
    return this.updateAction(userId, actionId, { isRead: true });
  }

  async markAllAsRead(userId: string) {
    await this.prisma.userAction.updateMany({
      where: { userId, isRead: false, isCompleted: false, isDismissed: false },
      data: { isRead: true },
    });

    return { success: true };
  }

  async dismissAction(userId: string, actionId: string) {
    return this.updateAction(userId, actionId, { isDismissed: true });
  }

  async completeAction(userId: string, actionId: string) {
    return this.updateAction(userId, actionId, { isCompleted: true });
  }

  private async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.userAction.count({
      where: {
        userId,
        isRead: false,
        isCompleted: false,
        isDismissed: false,
        OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
      },
    });
  }

  private async getHighPriorityCount(userId: string): Promise<number> {
    return this.prisma.userAction.count({
      where: {
        userId,
        priority: { in: [ActionPriority.HIGH, ActionPriority.URGENT] },
        isCompleted: false,
        isDismissed: false,
        OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
      },
    });
  }

  private formatAction(action: any) {
    return {
      id: action.id,
      type: action.type,
      priority: action.priority,
      title: action.title,
      description: action.description,
      actionUrl: action.actionUrl,
      referenceId: action.referenceId,
      dueDate: action.dueDate?.toISOString() || null,
      isRead: action.isRead,
      isDismissed: action.isDismissed,
      isCompleted: action.isCompleted,
      createdAt: action.createdAt.toISOString(),
      expiresAt: action.expiresAt?.toISOString() || null,
    };
  }
}
