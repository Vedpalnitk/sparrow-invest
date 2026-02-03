import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
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
import { CreateGoalDto, UpdateGoalDto, AddContributionDto, GoalResponseDto } from './dto/goal.dto';

/**
 * FA-specific goals controller
 * Allows Financial Advisors to manage goals for their clients
 */
@ApiTags('fa-goals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('api/v1/clients/:clientId/goals')
export class FAGoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Get()
  @ApiOperation({ summary: 'List all goals for a client' })
  @ApiResponse({ status: 200, type: [GoalResponseDto] })
  async findByClient(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
  ) {
    return this.goalsService.findAllByClient(clientId, user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific goal for a client' })
  @ApiResponse({ status: 200, type: GoalResponseDto })
  async findOne(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
    @Param('id') goalId: string,
  ) {
    return this.goalsService.findOneByClient(clientId, goalId, user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a goal for a client' })
  @ApiResponse({ status: 201, type: GoalResponseDto })
  async create(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
    @Body() dto: CreateGoalDto,
  ) {
    return this.goalsService.createForClient(clientId, user.id, dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a goal for a client' })
  @ApiResponse({ status: 200, type: GoalResponseDto })
  async update(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
    @Param('id') goalId: string,
    @Body() dto: UpdateGoalDto,
  ) {
    return this.goalsService.updateForClient(clientId, goalId, user.id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a goal for a client' })
  @ApiResponse({ status: 200 })
  async delete(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
    @Param('id') goalId: string,
  ) {
    await this.goalsService.deleteForClient(clientId, goalId, user.id);
    return { message: 'Goal deleted successfully' };
  }

  @Post(':id/contributions')
  @ApiOperation({ summary: 'Add a contribution to a goal' })
  @ApiResponse({ status: 201, type: GoalResponseDto })
  async addContribution(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
    @Param('id') goalId: string,
    @Body() dto: AddContributionDto,
  ) {
    return this.goalsService.addContributionForClient(clientId, goalId, user.id, dto);
  }

  @Get(':id/contributions')
  @ApiOperation({ summary: 'Get contributions for a goal' })
  async getContributions(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
    @Param('id') goalId: string,
  ) {
    return this.goalsService.getContributionsForClient(clientId, goalId, user.id);
  }
}
