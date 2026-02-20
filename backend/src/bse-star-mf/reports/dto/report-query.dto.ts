import { IsString, IsOptional, IsDateString, IsEnum } from 'class-validator'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'

export class OrderStatusQueryDto {
  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  fromDate?: string

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  toDate?: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  clientCode?: string

  @ApiPropertyOptional({ description: 'P (purchase) / R (redemption)' })
  @IsString()
  @IsOptional()
  orderType?: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  orderNumber?: string
}

export class AllotmentQueryDto {
  @ApiProperty()
  @IsDateString()
  fromDate: string

  @ApiProperty()
  @IsDateString()
  toDate: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  clientCode?: string
}

export class RedemptionQueryDto {
  @ApiProperty()
  @IsDateString()
  fromDate: string

  @ApiProperty()
  @IsDateString()
  toDate: string

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  clientCode?: string
}
