import {
  IsString,
  IsOptional,
  IsEmail,
  IsEnum,
  IsInt,
  Min,
  Max,
  IsDateString,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { RiskProfile, NomineeDto } from './create-client.dto';

export enum ClientStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  PENDING_KYC = 'PENDING_KYC',
}

export enum KycStatus {
  VERIFIED = 'VERIFIED',
  PENDING = 'PENDING',
  EXPIRED = 'EXPIRED',
}

export class UpdateClientDto {
  @ApiPropertyOptional({ example: 'Rajesh Sharma' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: 'rajesh.sharma@email.com' })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: '+91 98765 43210' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ example: 'ABCDE1234F' })
  @IsString()
  @IsOptional()
  pan?: string;

  @ApiPropertyOptional({ example: '1985-03-15' })
  @IsDateString()
  @IsOptional()
  dateOfBirth?: string;

  @ApiPropertyOptional({ example: '123 Main Street' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional({ example: 'Mumbai' })
  @IsString()
  @IsOptional()
  city?: string;

  @ApiPropertyOptional({ example: 'Maharashtra' })
  @IsString()
  @IsOptional()
  state?: string;

  @ApiPropertyOptional({ example: '400001' })
  @IsString()
  @IsOptional()
  pincode?: string;

  @ApiPropertyOptional({ enum: RiskProfile })
  @IsEnum(RiskProfile)
  @IsOptional()
  riskProfile?: RiskProfile;

  @ApiPropertyOptional({ enum: ClientStatus })
  @IsEnum(ClientStatus)
  @IsOptional()
  status?: ClientStatus;

  @ApiPropertyOptional({ enum: KycStatus })
  @IsEnum(KycStatus)
  @IsOptional()
  kycStatus?: KycStatus;

  @ApiPropertyOptional({ type: NomineeDto })
  @IsOptional()
  nominee?: NomineeDto;
}
