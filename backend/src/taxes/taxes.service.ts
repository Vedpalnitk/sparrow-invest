import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class TaxesService {
  constructor(private prisma: PrismaService) {}

  // Indian tax constants for FY 2024-25
  private readonly LTCG_EXEMPTION_LIMIT = 100000; // Rs 1 lakh
  private readonly LTCG_TAX_RATE = 0.10; // 10% after exemption
  private readonly STCG_TAX_RATE = 0.15; // 15% for equity

  async getTaxSummary(userId: string, financialYear?: string) {
    const fy = financialYear || this.getCurrentFinancialYear();

    let taxSummary = await this.prisma.userTaxSummary.findUnique({
      where: {
        userId_financialYear: { userId, financialYear: fy },
      },
      include: {
        capitalGains: {
          orderBy: { saleDate: 'desc' },
        },
      },
    });

    // If no summary exists, create a default one
    if (!taxSummary) {
      taxSummary = await this.prisma.userTaxSummary.create({
        data: {
          userId,
          financialYear: fy,
          ltcgRealized: 0,
          stcgRealized: 0,
          ltcgUnrealized: 0,
          stcgUnrealized: 0,
          elssInvested: 0,
          dividendReceived: 0,
          taxHarvestingDone: 0,
        },
        include: {
          capitalGains: true,
        },
      });
    }

    const taxEstimate = this.calculateTaxEstimate(
      this.toNumber(taxSummary.ltcgRealized),
      this.toNumber(taxSummary.stcgRealized),
    );

    return {
      id: taxSummary.id,
      financialYear: taxSummary.financialYear,
      ltcgRealized: this.toNumber(taxSummary.ltcgRealized),
      stcgRealized: this.toNumber(taxSummary.stcgRealized),
      ltcgUnrealized: this.toNumber(taxSummary.ltcgUnrealized),
      stcgUnrealized: this.toNumber(taxSummary.stcgUnrealized),
      elssInvested: this.toNumber(taxSummary.elssInvested),
      dividendReceived: this.toNumber(taxSummary.dividendReceived),
      taxHarvestingDone: this.toNumber(taxSummary.taxHarvestingDone),
      taxEstimate,
      capitalGains: taxSummary.capitalGains.map((cg) => ({
        id: cg.id,
        fundName: cg.fundName,
        fundSchemeCode: cg.fundSchemeCode,
        gainType: cg.gainType,
        purchaseDate: cg.purchaseDate.toISOString().split('T')[0],
        saleDate: cg.saleDate.toISOString().split('T')[0],
        purchaseValue: this.toNumber(cg.purchaseValue),
        saleValue: this.toNumber(cg.saleValue),
        gain: this.toNumber(cg.gain),
        taxableGain: this.toNumber(cg.taxableGain),
      })),
    };
  }

  async getCapitalGains(userId: string, financialYear?: string) {
    const fy = financialYear || this.getCurrentFinancialYear();

    const taxSummary = await this.prisma.userTaxSummary.findUnique({
      where: {
        userId_financialYear: { userId, financialYear: fy },
      },
      include: {
        capitalGains: {
          orderBy: { saleDate: 'desc' },
        },
      },
    });

    if (!taxSummary) {
      return { capitalGains: [], total: 0 };
    }

    return {
      capitalGains: taxSummary.capitalGains.map((cg) => ({
        id: cg.id,
        fundName: cg.fundName,
        fundSchemeCode: cg.fundSchemeCode,
        gainType: cg.gainType,
        purchaseDate: cg.purchaseDate.toISOString().split('T')[0],
        saleDate: cg.saleDate.toISOString().split('T')[0],
        purchaseValue: this.toNumber(cg.purchaseValue),
        saleValue: this.toNumber(cg.saleValue),
        gain: this.toNumber(cg.gain),
        taxableGain: this.toNumber(cg.taxableGain),
      })),
      total: taxSummary.capitalGains.length,
    };
  }

  private calculateTaxEstimate(ltcgRealized: number, stcgRealized: number) {
    // LTCG tax calculation with exemption
    const taxableLtcg = Math.max(0, ltcgRealized - this.LTCG_EXEMPTION_LIMIT);
    const ltcgTax = taxableLtcg * this.LTCG_TAX_RATE;

    // STCG tax (no exemption for equity)
    const stcgTax = stcgRealized * this.STCG_TAX_RATE;

    return {
      ltcgTax: Math.round(ltcgTax),
      stcgTax: Math.round(stcgTax),
      totalTax: Math.round(ltcgTax + stcgTax),
      ltcgExemption: this.LTCG_EXEMPTION_LIMIT,
      remainingExemption: Math.max(0, this.LTCG_EXEMPTION_LIMIT - ltcgRealized),
    };
  }

  private getCurrentFinancialYear(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;

    // FY starts in April
    if (month >= 4) {
      return `${year}-${(year + 1).toString().slice(-2)}`;
    } else {
      return `${year - 1}-${year.toString().slice(-2)}`;
    }
  }

  private toNumber(value: Decimal | number | null): number {
    if (value === null) return 0;
    if (typeof value === 'number') return value;
    return Number(value);
  }
}
