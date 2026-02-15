import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  InsurancePolicyType,
  InsurancePolicyStatus,
  PremiumFrequency,
} from './create-insurance-policy.dto';

export class UpdateInsurancePolicyDto {
  @ApiPropertyOptional({ example: 'LIC-12345678' })
  @IsString()
  @IsOptional()
  policyNumber?: string;

  @ApiPropertyOptional({ example: 'LIC' })
  @IsString()
  @IsOptional()
  provider?: string;

  @ApiPropertyOptional({ enum: InsurancePolicyType })
  @IsEnum(InsurancePolicyType)
  @IsOptional()
  type?: InsurancePolicyType;

  @ApiPropertyOptional({ enum: InsurancePolicyStatus })
  @IsEnum(InsurancePolicyStatus)
  @IsOptional()
  status?: InsurancePolicyStatus;

  @ApiPropertyOptional({ example: 10000000 })
  @IsNumber()
  @IsOptional()
  sumAssured?: number;

  @ApiPropertyOptional({ example: 15000 })
  @IsNumber()
  @IsOptional()
  premiumAmount?: number;

  @ApiPropertyOptional({ enum: PremiumFrequency })
  @IsEnum(PremiumFrequency)
  @IsOptional()
  premiumFrequency?: PremiumFrequency;

  @ApiPropertyOptional({ example: '2023-01-15' })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional({ example: '2053-01-15' })
  @IsDateString()
  @IsOptional()
  maturityDate?: string;

  @ApiPropertyOptional({ example: 'Spouse - Priya Sharma (100%)' })
  @IsString()
  @IsOptional()
  nominees?: string;

  @ApiPropertyOptional({ example: 'Updated notes' })
  @IsString()
  @IsOptional()
  notes?: string;
}
