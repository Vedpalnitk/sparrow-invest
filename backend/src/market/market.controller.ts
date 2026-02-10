import { Controller, Get, Param, Query, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { Public } from '../common/decorators/public.decorator';
import { MarketService } from './market.service';

@ApiTags('market')
@Controller('api/v1/market')
export class MarketController {
  constructor(private marketService: MarketService) {}

  @Get('indices')
  @Public()
  @ApiOperation({ summary: 'Get all market indices' })
  @ApiResponse({ status: 200, description: 'List of market indices with current values' })
  async getIndices() {
    return this.marketService.getIndices();
  }

  @Get('indices/:symbol')
  @Public()
  @ApiOperation({ summary: 'Get market index history' })
  @ApiResponse({ status: 200, description: 'Index history data for charts' })
  async getIndexHistory(
    @Param('symbol') symbol: string,
    @Query('days') days?: string,
  ) {
    const numDays = days ? parseInt(days, 10) : 30;
    const history = await this.marketService.getIndexHistory(symbol, numDays);

    if (!history) {
      throw new NotFoundException(`Index ${symbol} not found`);
    }

    return history;
  }

  @Get('status')
  @Public()
  @ApiOperation({ summary: 'Get market status (open/closed)' })
  @ApiResponse({ status: 200, description: 'Market status information' })
  async getMarketStatus() {
    return this.marketService.getMarketStatus();
  }
}
