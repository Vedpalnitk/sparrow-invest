import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum InsurancePolicyType {
  TERM_LIFE = 'TERM_LIFE',
  WHOLE_LIFE = 'WHOLE_LIFE',
  ENDOWMENT = 'ENDOWMENT',
  ULIP = 'ULIP',
  HEALTH = 'HEALTH',
  CRITICAL_ILLNESS = 'CRITICAL_ILLNESS',
  PERSONAL_ACCIDENT = 'PERSONAL_ACCIDENT',
  OTHER = 'OTHER',
}

export enum InsurancePolicyStatus {
  ACTIVE = 'ACTIVE',
  LAPSED = 'LAPSED',
  SURRENDERED = 'SURRENDERED',
  MATURED = 'MATURED',
  CLAIMED = 'CLAIMED',
}

export enum PremiumFrequency {
  MONTHLY = 'MONTHLY',
  QUARTERLY = 'QUARTERLY',
  HALF_YEARLY = 'HALF_YEARLY',
  ANNUAL = 'ANNUAL',
  SINGLE = 'SINGLE',
}

export class CreateInsurancePolicyDto {
  @ApiProperty({ example: 'LIC-12345678' })
  @IsString()
  policyNumber: string;

  @ApiProperty({ example: 'LIC' })
  @IsString()
  provider: string;

  @ApiProperty({ enum: InsurancePolicyType, example: InsurancePolicyType.TERM_LIFE })
  @IsEnum(InsurancePolicyType)
  type: InsurancePolicyType;

  @ApiPropertyOptional({ enum: InsurancePolicyStatus, default: InsurancePolicyStatus.ACTIVE })
  @IsEnum(InsurancePolicyStatus)
  @IsOptional()
  status?: InsurancePolicyStatus;

  @ApiProperty({ example: 10000000, description: 'Sum assured in INR' })
  @IsNumber()
  sumAssured: number;

  @ApiProperty({ example: 15000, description: 'Premium amount in INR' })
  @IsNumber()
  premiumAmount: number;

  @ApiPropertyOptional({ enum: PremiumFrequency, default: PremiumFrequency.ANNUAL })
  @IsEnum(PremiumFrequency)
  @IsOptional()
  premiumFrequency?: PremiumFrequency;

  @ApiProperty({ example: '2023-01-15' })
  @IsDateString()
  startDate: string;

  @ApiPropertyOptional({ example: '2053-01-15' })
  @IsDateString()
  @IsOptional()
  maturityDate?: string;

  @ApiPropertyOptional({ example: 'Spouse - Priya Sharma (100%)' })
  @IsString()
  @IsOptional()
  nominees?: string;

  @ApiPropertyOptional({ example: 'Online term plan with critical illness rider' })
  @IsString()
  @IsOptional()
  notes?: string;
}
