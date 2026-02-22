import { Module } from '@nestjs/common';
import { FundsController } from './funds.controller';
import { AmfiService } from './amfi.service';
import { MetricsCalculatorService } from './metrics-calculator.service';
import { FundSyncService } from './fund-sync.service';
import { AmfiTerService } from './amfi-ter.service';
import { AmfiAumService } from './amfi-aum.service';
import { SchemeEnrichmentService } from './scheme-enrichment.service';
import { AmfiHistoricalService } from './amfi-historical.service';
import { MetricsRecalcProcessor } from './metrics-recalc.processor';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [FundsController],
  providers: [
    AmfiService,
    MetricsCalculatorService,
    FundSyncService,
    AmfiTerService,
    AmfiAumService,
    SchemeEnrichmentService,
    AmfiHistoricalService,
    MetricsRecalcProcessor,
  ],
  exports: [FundSyncService, AmfiService, MetricsCalculatorService, AmfiTerService, AmfiAumService, SchemeEnrichmentService, AmfiHistoricalService],
})
export class FundsModule {}
