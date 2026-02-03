import { Module } from '@nestjs/common';
import { GoalsController } from './goals.controller';
import { FAGoalsController } from './fa-goals.controller';
import { AdvisorGoalsController } from './advisor-goals.controller';
import { GoalsService } from './goals.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [GoalsController, FAGoalsController, AdvisorGoalsController],
  providers: [GoalsService],
  exports: [GoalsService],
})
export class GoalsModule {}
