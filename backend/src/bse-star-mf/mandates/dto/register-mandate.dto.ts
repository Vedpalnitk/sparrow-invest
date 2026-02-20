import { IsString, IsNumber, IsOptional, IsEnum, IsDateString, Min } from 'class-validator'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'

export enum MandateType {
  XSIP = 'XSIP',
  ISIP = 'ISIP',
  NET_BANKING = 'NET_BANKING',
}

export class RegisterMandateDto {
  @ApiProperty({ description: 'Client ID' })
  @IsString()
  clientId: string

  @ApiProperty({ enum: MandateType })
  @IsEnum(MandateType)
  mandateType: MandateType

  @ApiProperty({ example: 50000 })
  @IsNumber()
  @Min(1)
  amount: number

  @ApiPropertyOptional({ description: 'Bank account ID from FABankAccount' })
  @IsString()
  @IsOptional()
  bankAccountId?: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  bankCode?: string

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  startDate?: string

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  endDate?: string
}

export class ShiftMandateDto {
  @ApiProperty()
  @IsString()
  fromMandateId: string

  @ApiProperty()
  @IsString()
  toMandateId: string
}
