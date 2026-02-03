import { IsString, IsNumber, IsOptional, IsEnum, IsArray, IsDateString, Min, Max } from 'class-validator';
import { GoalCategory, GoalStatus } from '@prisma/client';

export class CreateGoalDto {
  @IsString()
  name: string;

  @IsEnum(GoalCategory)
  category: GoalCategory;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsNumber()
  @Min(0)
  targetAmount: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  currentAmount?: number;

  @IsDateString()
  targetDate: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  monthlySip?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  priority?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  linkedFundCodes?: string[];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateGoalDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(GoalCategory)
  category?: GoalCategory;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  targetAmount?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  currentAmount?: number;

  @IsOptional()
  @IsDateString()
  targetDate?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  monthlySip?: number;

  @IsOptional()
  @IsEnum(GoalStatus)
  status?: GoalStatus;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  priority?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  linkedFundCodes?: string[];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class AddContributionDto {
  @IsNumber()
  @Min(0)
  amount: number;

  @IsString()
  type: string; // SIP, LUMPSUM, RETURNS, DIVIDEND

  @IsDateString()
  date: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class GoalResponseDto {
  id: string;
  name: string;
  category: GoalCategory;
  icon: string | null;
  targetAmount: number;
  currentAmount: number;
  targetDate: string;
  monthlySip: number | null;
  status: GoalStatus;
  priority: number;
  linkedFundCodes: string[];
  notes: string | null;
  progress: number; // Percentage
  daysRemaining: number;
  createdAt: string;
  updatedAt: string;
}
