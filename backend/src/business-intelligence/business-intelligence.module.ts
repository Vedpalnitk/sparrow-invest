import { Module } from '@nestjs/common';
import { BusinessIntelligenceController } from './business-intelligence.controller';
import { BusinessIntelligenceService } from './business-intelligence.service';
import { AumSnapshotScheduler } from './aum-snapshot.scheduler';

@Module({
  controllers: [BusinessIntelligenceController],
  providers: [BusinessIntelligenceService, AumSnapshotScheduler],
  exports: [BusinessIntelligenceService],
})
export class BusinessIntelligenceModule {}
