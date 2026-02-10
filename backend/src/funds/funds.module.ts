import { Module } from '@nestjs/common';
import { FundsController } from './funds.controller';
import { MfApiService } from './mfapi.service';
import { KuveraService } from './kuvera.service';
import { FundSyncService } from './fund-sync.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [FundsController],
  providers: [MfApiService, KuveraService, FundSyncService],
  exports: [MfApiService, KuveraService, FundSyncService],
})
export class FundsModule {}
