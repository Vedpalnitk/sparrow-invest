import {
  Controller,
  Get,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { GoalsService } from './goals.service';
import { GoalResponseDto } from './dto/goal.dto';

/**
 * Advisor-wide goals controller
 * Returns goals across all clients for the advisor dashboard
 */
@ApiTags('advisor-goals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('api/v1/goals')
export class AdvisorGoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Get()
  @ApiOperation({ summary: 'List all goals across all clients (for advisor dashboard)' })
  @ApiResponse({ status: 200, type: [GoalResponseDto] })
  async findAll(@CurrentUser() user: any) {
    return this.goalsService.findAllByAdvisor(user.id);
  }
}
