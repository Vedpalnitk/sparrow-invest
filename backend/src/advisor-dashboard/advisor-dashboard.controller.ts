import { Controller, Get, UseGuards } from '@nestjs/common'
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger'
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard'
import { CurrentUser } from '../common/decorators/current-user.decorator'
import { AdvisorDashboardService } from './advisor-dashboard.service'

@ApiTags('advisor-dashboard')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('api/v1/advisor')
export class AdvisorDashboardController {
  constructor(private dashboardService: AdvisorDashboardService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get advisor dashboard data with KPIs, top performers, SIPs, and growth metrics' })
  @ApiResponse({ status: 200, description: 'Dashboard data returned successfully' })
  async getDashboard(@CurrentUser() user: any) {
    return this.dashboardService.getDashboard(user.id)
  }

  @Get('insights')
  @ApiOperation({ summary: 'Get advisor insights: portfolio health, rebalancing, tax harvesting, goal alerts' })
  @ApiResponse({ status: 200, description: 'Insights data returned successfully' })
  async getInsights(@CurrentUser() user: any) {
    return this.dashboardService.getInsights(user.id)
  }
}
