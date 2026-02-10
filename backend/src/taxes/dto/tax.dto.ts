import { ApiProperty } from '@nestjs/swagger';

export class TaxSummaryResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  financialYear: string;

  @ApiProperty()
  ltcgRealized: number;

  @ApiProperty()
  stcgRealized: number;

  @ApiProperty()
  ltcgUnrealized: number;

  @ApiProperty()
  stcgUnrealized: number;

  @ApiProperty()
  elssInvested: number;

  @ApiProperty()
  dividendReceived: number;

  @ApiProperty()
  taxHarvestingDone: number;

  @ApiProperty({ required: false })
  capitalGains?: CapitalGainDto[];
}

export class CapitalGainDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  fundName: string;

  @ApiProperty()
  fundSchemeCode: string;

  @ApiProperty({ enum: ['LTCG', 'STCG'] })
  gainType: string;

  @ApiProperty()
  purchaseDate: string;

  @ApiProperty()
  saleDate: string;

  @ApiProperty()
  purchaseValue: number;

  @ApiProperty()
  saleValue: number;

  @ApiProperty()
  gain: number;

  @ApiProperty()
  taxableGain: number;
}

export class TaxEstimateDto {
  @ApiProperty()
  ltcgTax: number;

  @ApiProperty()
  stcgTax: number;

  @ApiProperty()
  totalTax: number;

  @ApiProperty()
  ltcgExemption: number;

  @ApiProperty()
  remainingExemption: number;
}
