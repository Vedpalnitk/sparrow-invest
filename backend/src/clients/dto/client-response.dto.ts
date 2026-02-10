import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class BankAccountResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  bankName: string;

  @ApiProperty()
  accountNumber: string;

  @ApiProperty()
  ifsc: string;

  @ApiProperty()
  accountType: string;

  @ApiProperty()
  isPrimary: boolean;

  @ApiPropertyOptional()
  mandateStatus?: string;
}

export class NomineeResponseDto {
  @ApiProperty()
  name: string;

  @ApiProperty()
  relationship: string;

  @ApiProperty()
  percentage: number;
}

export class ClientResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  email: string;

  @ApiProperty()
  phone: string;

  @ApiPropertyOptional()
  pan?: string;

  @ApiPropertyOptional()
  dateOfBirth?: string;

  @ApiPropertyOptional()
  address?: string;

  @ApiPropertyOptional()
  city?: string;

  @ApiPropertyOptional()
  state?: string;

  @ApiPropertyOptional()
  pincode?: string;

  @ApiProperty()
  aum: number;

  @ApiProperty()
  returns: number;

  @ApiProperty({ enum: ['Conservative', 'Moderate', 'Aggressive'] })
  riskProfile: string;

  @ApiProperty()
  lastActive: string;

  @ApiProperty()
  sipCount: number;

  @ApiProperty()
  goalsCount: number;

  @ApiProperty()
  joinedDate: string;

  @ApiProperty({ enum: ['Active', 'Inactive', 'Pending KYC'] })
  status: string;

  @ApiPropertyOptional({ enum: ['Verified', 'Pending', 'Expired'] })
  kycStatus?: string;

  @ApiPropertyOptional({ type: NomineeResponseDto })
  nominee?: NomineeResponseDto;

  @ApiPropertyOptional({ type: [BankAccountResponseDto] })
  bankAccounts?: BankAccountResponseDto[];
}

export class ClientWithPortfolioDto extends ClientResponseDto {
  @ApiPropertyOptional()
  totalInvested?: number;

  @ApiPropertyOptional()
  currentValue?: number;

  @ApiPropertyOptional()
  absoluteGain?: number;

  @ApiPropertyOptional()
  absoluteGainPercent?: number;

  @ApiPropertyOptional()
  xirr?: number;

  @ApiPropertyOptional()
  holdingsCount?: number;
}

export class PaginatedClientsResponseDto {
  @ApiProperty({ type: [ClientResponseDto] })
  data: ClientResponseDto[];

  @ApiProperty()
  total: number;

  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  totalPages: number;
}
