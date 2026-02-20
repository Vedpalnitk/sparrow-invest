import { IsString, IsEnum, IsOptional } from 'class-validator'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'

export enum PaymentMode {
  DIRECT = 'DIRECT',
  NODAL = 'NODAL',
  NEFT = 'NEFT',
  UPI = 'UPI',
}

export class InitiatePaymentDto {
  @ApiProperty({ enum: PaymentMode }) @IsEnum(PaymentMode) paymentMode: PaymentMode
  @ApiPropertyOptional() @IsString() @IsOptional() bankCode?: string
}
