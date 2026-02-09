import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SIPResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  clientId: string;

  @ApiProperty()
  clientName: string;

  @ApiProperty()
  fundName: string;

  @ApiProperty()
  fundSchemeCode: string;

  @ApiProperty()
  folioNumber: string;

  @ApiProperty()
  amount: number;

  @ApiProperty({ enum: ['Daily', 'Weekly', 'Monthly', 'Quarterly'] })
  frequency: string;

  @ApiProperty({ description: 'Day of month (1-28)' })
  sipDate: number;

  @ApiProperty()
  startDate: string;

  @ApiPropertyOptional()
  endDate?: string;

  @ApiProperty({ enum: ['Active', 'Paused', 'Completed', 'Cancelled', 'Failed'] })
  status: string;

  @ApiProperty()
  totalInstallments: number;

  @ApiProperty()
  completedInstallments: number;

  @ApiProperty()
  totalInvested: number;

  @ApiProperty()
  currentValue: number;

  @ApiProperty()
  returns: number;

  @ApiProperty()
  returnsPercent: number;

  @ApiProperty()
  nextSipDate: string;

  @ApiPropertyOptional()
  lastSipDate?: string;

  @ApiPropertyOptional()
  mandateId?: string;

  @ApiPropertyOptional()
  stepUpPercent?: number;

  @ApiPropertyOptional({ enum: ['Yearly', 'Half-Yearly'] })
  stepUpFrequency?: string;
}

export class PaginatedSIPsResponseDto {
  @ApiProperty({ type: [SIPResponseDto] })
  data: SIPResponseDto[];

  @ApiProperty()
  total: number;

  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  totalPages: number;
}
