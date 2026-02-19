import { Module } from '@nestjs/common';
import { ComplianceController } from './compliance.controller';
import { ComplianceService } from './compliance.service';
import { ComplianceScheduler } from './compliance.scheduler';

@Module({
  controllers: [ComplianceController],
  providers: [ComplianceService, ComplianceScheduler],
  exports: [ComplianceService],
})
export class ComplianceModule {}
