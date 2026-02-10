import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PortfolioAnalysisController } from './portfolio-analysis.controller';
import { PortfolioAnalysisService } from './portfolio-analysis.service';

@Module({
  imports: [ConfigModule],
  controllers: [PortfolioAnalysisController],
  providers: [PortfolioAnalysisService],
  exports: [PortfolioAnalysisService],
})
export class PortfolioAnalysisModule {}
