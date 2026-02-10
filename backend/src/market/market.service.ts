import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MarketService {
  constructor(private prisma: PrismaService) {}

  async getIndices() {
    const indices = await this.prisma.marketIndex.findMany({
      where: { isActive: true },
      orderBy: { symbol: 'asc' },
    });

    return indices.map((index) => ({
      id: index.id,
      symbol: index.symbol,
      name: index.name,
      currentValue: Number(index.currentValue),
      change: Number(index.change),
      changePercent: Number(index.changePercent),
      previousClose: Number(index.previousClose),
      dayHigh: index.dayHigh ? Number(index.dayHigh) : null,
      dayLow: index.dayLow ? Number(index.dayLow) : null,
      lastUpdated: index.lastUpdated.toISOString(),
    }));
  }

  async getIndexHistory(symbol: string, days: number = 30) {
    const index = await this.prisma.marketIndex.findUnique({
      where: { symbol },
    });

    if (!index) {
      return null;
    }

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const history = await this.prisma.marketIndexHistory.findMany({
      where: {
        indexId: index.id,
        date: {
          gte: startDate,
        },
      },
      orderBy: {
        date: 'asc',
      },
    });

    return {
      symbol: index.symbol,
      name: index.name,
      period: days,
      data: history.map((h) => ({
        date: h.date.toISOString().split('T')[0],
        open: Number(h.open),
        high: Number(h.high),
        low: Number(h.low),
        close: Number(h.close),
        volume: h.volume ? Number(h.volume) : null,
      })),
    };
  }

  async getMarketStatus() {
    // Check if market is open (Indian market hours: 9:15 AM - 3:30 PM IST, Mon-Fri)
    const now = new Date();
    const istOffset = 5.5 * 60 * 60 * 1000; // IST is UTC+5:30
    const istTime = new Date(now.getTime() + istOffset);

    const dayOfWeek = istTime.getUTCDay();
    const hours = istTime.getUTCHours();
    const minutes = istTime.getUTCMinutes();
    const timeInMinutes = hours * 60 + minutes;

    const marketOpen = 9 * 60 + 15; // 9:15 AM
    const marketClose = 15 * 60 + 30; // 3:30 PM

    const isWeekday = dayOfWeek >= 1 && dayOfWeek <= 5;
    const isMarketHours = timeInMinutes >= marketOpen && timeInMinutes <= marketClose;
    const isOpen = isWeekday && isMarketHours;

    return {
      isOpen,
      status: isOpen ? 'OPEN' : 'CLOSED',
      message: isOpen
        ? 'Market is currently open'
        : isWeekday
          ? 'Market is closed for the day'
          : 'Market is closed for the weekend',
      nextOpen: isOpen
        ? null
        : this.getNextMarketOpen(istTime),
    };
  }

  private getNextMarketOpen(currentIst: Date): string {
    const next = new Date(currentIst);

    // If it's after market close on a weekday, next open is tomorrow
    // If it's weekend, find next Monday
    let daysToAdd = 1;
    const dayOfWeek = next.getUTCDay();

    if (dayOfWeek === 5) {
      // Friday after market close
      daysToAdd = 3;
    } else if (dayOfWeek === 6) {
      // Saturday
      daysToAdd = 2;
    } else if (dayOfWeek === 0) {
      // Sunday
      daysToAdd = 1;
    }

    next.setUTCDate(next.getUTCDate() + daysToAdd);
    next.setUTCHours(9, 15, 0, 0);

    // Convert back to IST for display
    return next.toISOString();
  }
}
