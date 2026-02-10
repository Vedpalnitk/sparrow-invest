import { IsOptional, IsString, IsInt, Min, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export enum SortField {
  NAME = 'name',
  AUM = 'aum',
  RETURNS = 'returns',
  JOINED_DATE = 'joinedDate',
  LAST_ACTIVE = 'lastActive',
}

export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc',
}

export class ClientFilterDto {
  @ApiPropertyOptional({ example: 1 })
  @IsInt()
  @Min(1)
  @Type(() => Number)
  @IsOptional()
  page?: number = 1;

  @ApiPropertyOptional({ example: 20 })
  @IsInt()
  @Min(1)
  @Type(() => Number)
  @IsOptional()
  limit?: number = 20;

  @ApiPropertyOptional({ example: 'rajesh' })
  @IsString()
  @IsOptional()
  search?: string;

  @ApiPropertyOptional({ enum: ['CONSERVATIVE', 'MODERATE', 'AGGRESSIVE'] })
  @IsString()
  @IsOptional()
  riskProfile?: string;

  @ApiPropertyOptional({ enum: ['ACTIVE', 'INACTIVE', 'PENDING_KYC'] })
  @IsString()
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ enum: SortField })
  @IsEnum(SortField)
  @IsOptional()
  sortBy?: SortField = SortField.AUM;

  @ApiPropertyOptional({ enum: SortOrder })
  @IsEnum(SortOrder)
  @IsOptional()
  sortOrder?: SortOrder = SortOrder.DESC;
}
