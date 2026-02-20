import { IsString, IsOptional, IsEnum, IsDateString, Matches, Length, MaxLength } from 'class-validator'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'

export enum UccTransactionType {
  NEW = 'NEW',
  MOD = 'MOD',
}

export class RegisterUccDto {
  @ApiProperty({ enum: UccTransactionType, default: UccTransactionType.NEW })
  @IsEnum(UccTransactionType)
  transType: UccTransactionType = UccTransactionType.NEW

  @ApiProperty({ example: '01', description: 'Tax status code' })
  @IsString()
  taxStatus: string

  @ApiPropertyOptional({ example: 'SI', description: 'Holding nature: SI/JO/AS' })
  @IsString()
  @IsOptional()
  holdingNature?: string = 'SI'

  @ApiPropertyOptional({ example: '01', description: 'Occupation code' })
  @IsString()
  @IsOptional()
  occupationCode?: string

  @ApiPropertyOptional({ description: 'Second holder PAN' })
  @IsString()
  @IsOptional()
  @Matches(/^[A-Z]{5}\d{4}[A-Z]$/, { message: 'Invalid PAN format' })
  secondHolderPan?: string

  @ApiPropertyOptional({ description: 'Third holder PAN' })
  @IsString()
  @IsOptional()
  @Matches(/^[A-Z]{5}\d{4}[A-Z]$/, { message: 'Invalid PAN format' })
  thirdHolderPan?: string

  @ApiPropertyOptional({ description: 'Guardian PAN (for minor)' })
  @IsString()
  @IsOptional()
  guardianPan?: string

  @ApiPropertyOptional({ description: 'Nominee name' })
  @IsString()
  @IsOptional()
  @MaxLength(40)
  nomineeName?: string

  @ApiPropertyOptional({ description: 'Nominee relation' })
  @IsString()
  @IsOptional()
  nomineeRelation?: string

  @ApiPropertyOptional({ description: 'Communication mode: E (email) / P (physical)' })
  @IsString()
  @IsOptional()
  communicationMode?: string = 'E'

  @ApiPropertyOptional({ description: 'Dividend pay mode: 02 (bank transfer)' })
  @IsString()
  @IsOptional()
  dividendPayMode?: string = '02'
}

export class UploadFatcaDto {
  @ApiProperty({ description: 'PAN of investor' })
  @IsString()
  @Matches(/^[A-Z]{5}\d{4}[A-Z]$/)
  pan: string

  @ApiPropertyOptional({ example: '01', description: 'Tax status code (e.g. 01=Individual)' })
  @IsString()
  @IsOptional()
  taxStatus?: string = '01'

  @ApiProperty({ description: 'Country of birth code' })
  @IsString()
  countryOfBirth: string = 'IN'

  @ApiProperty({ description: 'Country of citizenship' })
  @IsString()
  citizenshipCountry: string = 'IN'

  @ApiProperty({ description: 'Country of nationality' })
  @IsString()
  nationalityCountry: string = 'IN'

  @ApiPropertyOptional({ description: 'Source of wealth' })
  @IsString()
  @IsOptional()
  sourceOfWealth?: string = '02' // Salary

  @ApiPropertyOptional({ description: 'Income slab: 31-36' })
  @IsString()
  @IsOptional()
  incomeSlab?: string = '31' // Below 1 Lakh

  @ApiPropertyOptional({ description: 'Politically Exposed Person: Y/N/R' })
  @IsString()
  @IsOptional()
  pepStatus?: string = 'N'

  @ApiPropertyOptional({ description: 'Address type: 1=Residential, 2=Business, etc.' })
  @IsString()
  @IsOptional()
  addressType?: string = '1'
}

export class UploadCkycDto {
  @ApiProperty({ description: 'CKYC number' })
  @IsString()
  ckycNumber: string

  @ApiProperty({ description: 'PAN of investor' })
  @IsString()
  @Matches(/^[A-Z]{5}\d{4}[A-Z]$/)
  pan: string
}
