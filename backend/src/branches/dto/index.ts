import { IsString, IsOptional, IsBoolean } from 'class-validator'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'

export class CreateBranchDto {
  @ApiProperty({ example: 'Mumbai Office' })
  @IsString()
  name: string

  @ApiPropertyOptional({ example: 'Mumbai' })
  @IsString()
  @IsOptional()
  city?: string

  @ApiPropertyOptional({ example: 'MUM-001' })
  @IsString()
  @IsOptional()
  code?: string
}

export class UpdateBranchDto {
  @ApiPropertyOptional({ example: 'Mumbai HQ' })
  @IsString()
  @IsOptional()
  name?: string

  @ApiPropertyOptional({ example: 'Mumbai' })
  @IsString()
  @IsOptional()
  city?: string

  @ApiPropertyOptional({ example: 'MUM-001' })
  @IsString()
  @IsOptional()
  code?: string

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean
}
