import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsBoolean, IsDateString } from 'class-validator';

export enum ActionType {
  SIP_DUE = 'SIP_DUE',
  SIP_FAILED = 'SIP_FAILED',
  REBALANCE_RECOMMENDED = 'REBALANCE_RECOMMENDED',
  GOAL_REVIEW = 'GOAL_REVIEW',
  TAX_HARVESTING = 'TAX_HARVESTING',
  KYC_EXPIRY = 'KYC_EXPIRY',
  DIVIDEND_RECEIVED = 'DIVIDEND_RECEIVED',
  NAV_ALERT = 'NAV_ALERT',
  CUSTOM = 'CUSTOM',
}

export enum ActionPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export class CreateActionDto {
  @ApiProperty({ enum: ActionType })
  @IsEnum(ActionType)
  type: ActionType;

  @ApiPropertyOptional({ enum: ActionPriority })
  @IsEnum(ActionPriority)
  @IsOptional()
  priority?: ActionPriority;

  @ApiProperty()
  @IsString()
  title: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  actionUrl?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  referenceId?: string;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  expiresAt?: string;
}

export class UpdateActionDto {
  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isRead?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isDismissed?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isCompleted?: boolean;
}

export class ActionResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ enum: ActionType })
  type: ActionType;

  @ApiProperty({ enum: ActionPriority })
  priority: ActionPriority;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  actionUrl?: string;

  @ApiPropertyOptional()
  referenceId?: string;

  @ApiPropertyOptional()
  dueDate?: string;

  @ApiProperty()
  isRead: boolean;

  @ApiProperty()
  isDismissed: boolean;

  @ApiProperty()
  isCompleted: boolean;

  @ApiProperty()
  createdAt: string;

  @ApiPropertyOptional()
  expiresAt?: string;
}
