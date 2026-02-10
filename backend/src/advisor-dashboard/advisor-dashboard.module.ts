import { Module } from '@nestjs/common'
import { AdvisorDashboardController } from './advisor-dashboard.controller'
import { AdvisorDashboardService } from './advisor-dashboard.service'

@Module({
  controllers: [AdvisorDashboardController],
  providers: [AdvisorDashboardService],
  exports: [AdvisorDashboardService],
})
export class AdvisorDashboardModule {}
