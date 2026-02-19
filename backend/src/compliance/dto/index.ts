import { IsString, IsOptional, IsEnum, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateComplianceDto {
  @ApiProperty({ enum: ['ARN', 'EUIN', 'KYC', 'SEBI_REGISTRATION', 'INSURANCE_LICENSE'] })
  @IsEnum(['ARN', 'EUIN', 'KYC', 'SEBI_REGISTRATION', 'INSURANCE_LICENSE'])
  type: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  entityId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  entityName?: string;

  @ApiProperty()
  @IsDateString()
  expiryDate: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  documentUrl?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}

export class UpdateComplianceDto {
  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  expiryDate?: string;

  @ApiPropertyOptional()
  @IsEnum(['VALID', 'EXPIRING_SOON', 'EXPIRED'])
  @IsOptional()
  status?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  documentUrl?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}

export class ComplianceFilterDto {
  @ApiPropertyOptional({ enum: ['ARN', 'EUIN', 'KYC', 'SEBI_REGISTRATION', 'INSURANCE_LICENSE'] })
  @IsEnum(['ARN', 'EUIN', 'KYC', 'SEBI_REGISTRATION', 'INSURANCE_LICENSE'])
  @IsOptional()
  type?: string;

  @ApiPropertyOptional({ enum: ['VALID', 'EXPIRING_SOON', 'EXPIRED'] })
  @IsEnum(['VALID', 'EXPIRING_SOON', 'EXPIRED'])
  @IsOptional()
  status?: string;
}
