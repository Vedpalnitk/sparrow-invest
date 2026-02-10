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
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum RiskProfile {
  CONSERVATIVE = 'CONSERVATIVE',
  MODERATE = 'MODERATE',
  AGGRESSIVE = 'AGGRESSIVE',
}

export class NomineeDto {
  @ApiProperty({ example: 'Spouse Name' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'Spouse' })
  @IsString()
  relationship: string;

  @ApiProperty({ example: 100 })
  @IsInt()
  @Min(1)
  @Max(100)
  percentage: number;
}

export class CreateClientDto {
  @ApiProperty({ example: 'Rajesh Sharma' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'rajesh.sharma@email.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '+91 98765 43210' })
  @IsString()
  phone: string;

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

  @ApiPropertyOptional({ enum: RiskProfile, default: RiskProfile.MODERATE })
  @IsEnum(RiskProfile)
  @IsOptional()
  riskProfile?: RiskProfile;

  @ApiPropertyOptional({ type: NomineeDto })
  @IsOptional()
  nominee?: NomineeDto;
}
