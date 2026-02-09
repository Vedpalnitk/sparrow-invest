import { IsString, IsNumber, IsOptional, IsEnum, IsDateString, IsBoolean, IsInt, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum SIPFrequency {
  DAILY = 'DAILY',
  WEEKLY = 'WEEKLY',
  MONTHLY = 'MONTHLY',
  QUARTERLY = 'QUARTERLY',
}

export enum StepUpFrequency {
  YEARLY = 'Yearly',
  HALF_YEARLY = 'Half-Yearly',
}

export class CreateSIPDto {
  @ApiProperty()
  @IsString()
  clientId: string;

  @ApiProperty({ example: 'Axis Bluechip Fund - Direct Growth' })
  @IsString()
  fundName: string;

  @ApiProperty({ example: '120503' })
  @IsString()
  fundSchemeCode: string;

  @ApiProperty({ example: '123456789012' })
  @IsString()
  folioNumber: string;

  @ApiProperty({ example: 10000 })
  @IsNumber()
  @Min(500)
  amount: number;

  @ApiProperty({ enum: SIPFrequency, default: SIPFrequency.MONTHLY })
  @IsEnum(SIPFrequency)
  frequency: SIPFrequency;

  @ApiProperty({ example: 5, description: 'Day of month (1-28)' })
  @IsInt()
  @Min(1)
  @Max(28)
  sipDate: number;

  @ApiProperty({ example: '2024-02-01' })
  @IsDateString()
  startDate: string;

  @ApiPropertyOptional({ example: '2029-02-01' })
  @IsDateString()
  @IsOptional()
  endDate?: string;

  @ApiPropertyOptional({ default: false })
  @IsBoolean()
  @IsOptional()
  isPerpetual?: boolean;

  @ApiPropertyOptional({ example: 10, description: 'Step up percentage' })
  @IsInt()
  @Min(0)
  @Max(100)
  @IsOptional()
  stepUpPercent?: number;

  @ApiPropertyOptional({ enum: StepUpFrequency })
  @IsEnum(StepUpFrequency)
  @IsOptional()
  stepUpFrequency?: StepUpFrequency;
}

export class UpdateSIPDto {
  @ApiPropertyOptional({ example: 15000 })
  @IsNumber()
  @Min(500)
  @IsOptional()
  amount?: number;

  @ApiPropertyOptional({ example: 10 })
  @IsInt()
  @Min(1)
  @Max(28)
  @IsOptional()
  sipDate?: number;

  @ApiPropertyOptional({ example: '2030-02-01' })
  @IsDateString()
  @IsOptional()
  endDate?: string;

  @ApiPropertyOptional({ example: 15 })
  @IsInt()
  @Min(0)
  @Max(100)
  @IsOptional()
  stepUpPercent?: number;

  @ApiPropertyOptional({ enum: StepUpFrequency })
  @IsEnum(StepUpFrequency)
  @IsOptional()
  stepUpFrequency?: StepUpFrequency;
}
