import { IsString, IsOptional, IsEnum, IsDateString, IsUUID } from 'class-validator'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'

export enum TaskStatusDto {
  OPEN = 'OPEN',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum TaskCategoryDto {
  FOLLOW_UP = 'FOLLOW_UP',
  REVIEW = 'REVIEW',
  ONBOARDING = 'ONBOARDING',
  KYC_UPDATE = 'KYC_UPDATE',
  COMPLAINT = 'COMPLAINT',
  GENERAL = 'GENERAL',
}

export enum TaskPriorityDto {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export enum ActivityTypeDto {
  CALL = 'CALL',
  EMAIL = 'EMAIL',
  MEETING = 'MEETING',
  NOTE = 'NOTE',
  TASK_CREATED = 'TASK_CREATED',
  TASK_COMPLETED = 'TASK_COMPLETED',
}

export class CreateTaskDto {
  @ApiProperty({ example: 'Follow up with client on SIP review' })
  @IsString()
  title: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  clientId?: string

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  assignedToId?: string

  @ApiPropertyOptional({ example: '2026-03-01' })
  @IsDateString()
  @IsOptional()
  dueDate?: string

  @ApiPropertyOptional({ enum: TaskPriorityDto })
  @IsEnum(TaskPriorityDto)
  @IsOptional()
  priority?: TaskPriorityDto

  @ApiPropertyOptional({ enum: TaskCategoryDto })
  @IsEnum(TaskCategoryDto)
  @IsOptional()
  category?: TaskCategoryDto
}

export class UpdateTaskDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  title?: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  clientId?: string

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  assignedToId?: string

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  dueDate?: string

  @ApiPropertyOptional({ enum: TaskPriorityDto })
  @IsEnum(TaskPriorityDto)
  @IsOptional()
  priority?: TaskPriorityDto

  @ApiPropertyOptional({ enum: TaskStatusDto })
  @IsEnum(TaskStatusDto)
  @IsOptional()
  status?: TaskStatusDto

  @ApiPropertyOptional({ enum: TaskCategoryDto })
  @IsEnum(TaskCategoryDto)
  @IsOptional()
  category?: TaskCategoryDto
}

export class TaskFilterDto {
  @IsOptional() @IsString() status?: string
  @IsOptional() @IsString() priority?: string
  @IsOptional() @IsString() category?: string
  @IsOptional() @IsString() assignedToId?: string
  @IsOptional() @IsString() clientId?: string
}

export class CreateActivityDto {
  @ApiProperty({ enum: ActivityTypeDto })
  @IsEnum(ActivityTypeDto)
  type: ActivityTypeDto

  @ApiProperty({ example: 'Discussed portfolio rebalancing options' })
  @IsString()
  summary: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  details?: string

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  clientId?: string
}

export class ActivityFilterDto {
  @IsOptional() @IsString() clientId?: string
  @IsOptional() @IsString() staffId?: string
  @IsOptional() @IsString() type?: string
  @IsOptional() @IsString() from?: string
  @IsOptional() @IsString() to?: string
}
