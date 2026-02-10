import { Module } from '@nestjs/common';
import { AdvisorsController } from './advisors.controller';
import { AdvisorsService } from './advisors.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AdvisorsController],
  providers: [AdvisorsService],
  exports: [AdvisorsService],
})
export class AdvisorsModule {}
