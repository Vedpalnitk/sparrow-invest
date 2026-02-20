import { IsString, IsNumber, IsOptional, IsEnum, IsDateString, Min, Max } from 'class-validator'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'

export enum SipFrequency {
  DAILY = 'DAILY',
  WEEKLY = 'WEEKLY',
  FORTNIGHTLY = 'FORTNIGHTLY',
  MONTHLY = 'MONTHLY',
  QUARTERLY = 'QUARTERLY',
}

export class RegisterSipDto {
  @ApiProperty()
  @IsString()
  clientId: string

  @ApiProperty()
  @IsString()
  schemeCode: string

  @ApiProperty({ example: 5000 })
  @IsNumber()
  @Min(100)
  amount: number

  @ApiProperty({ enum: SipFrequency, default: SipFrequency.MONTHLY })
  @IsEnum(SipFrequency)
  frequency: SipFrequency = SipFrequency.MONTHLY

  @ApiProperty({ example: 1, description: 'SIP day (1-28)' })
  @IsNumber()
  @Min(1)
  @Max(28)
  sipDay: number

  @ApiProperty()
  @IsDateString()
  startDate: string

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  endDate?: string

  @ApiPropertyOptional({ example: 60, description: 'Number of installments' })
  @IsNumber()
  @IsOptional()
  installments?: number

  @ApiPropertyOptional({ description: 'Y to place first order today' })
  @IsString()
  @IsOptional()
  firstOrderFlag?: string = 'Y'

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  folioNumber?: string

  @ApiPropertyOptional({ description: 'Link to existing FASIP record' })
  @IsString()
  @IsOptional()
  sipId?: string
}

export class RegisterXsipDto extends RegisterSipDto {
  @ApiProperty({ description: 'Mandate ID for XSIP' })
  @IsString()
  mandateId: string

  @ApiPropertyOptional({ description: 'Units instead of amount' })
  @IsNumber()
  @IsOptional()
  units?: number
}

export class RegisterStpDto {
  @ApiProperty()
  @IsString()
  clientId: string

  @ApiProperty({ description: 'Source scheme code' })
  @IsString()
  fromSchemeCode: string

  @ApiProperty({ description: 'Target scheme code' })
  @IsString()
  toSchemeCode: string

  @ApiProperty({ example: 5000 })
  @IsNumber()
  @Min(100)
  amount: number

  @ApiProperty({ enum: SipFrequency, default: SipFrequency.MONTHLY })
  @IsEnum(SipFrequency)
  frequency: SipFrequency = SipFrequency.MONTHLY

  @ApiProperty()
  @IsDateString()
  startDate: string

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  endDate?: string

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  installments?: number

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  folioNumber?: string

  @ApiPropertyOptional({ description: 'EXCHANGE or AMC' })
  @IsString()
  @IsOptional()
  stpType?: string = 'EXCHANGE'
}

export class RegisterSwpDto {
  @ApiProperty()
  @IsString()
  clientId: string

  @ApiProperty()
  @IsString()
  schemeCode: string

  @ApiProperty({ example: 5000 })
  @IsNumber()
  @Min(100)
  amount: number

  @ApiProperty({ enum: SipFrequency, default: SipFrequency.MONTHLY })
  @IsEnum(SipFrequency)
  frequency: SipFrequency = SipFrequency.MONTHLY

  @ApiProperty()
  @IsDateString()
  startDate: string

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  endDate?: string

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  installments?: number

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  folioNumber?: string
}

export class CancelSystematicDto {
  @ApiProperty({ description: 'BSE registration number' })
  @IsString()
  registrationNumber: string
}
