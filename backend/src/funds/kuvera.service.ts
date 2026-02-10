import { Injectable, Logger } from '@nestjs/common';

/**
 * Kuvera API Service
 * Fetches real mutual fund data from Kuvera's public API via mf.captnemo.in proxy.
 *
 * Data includes:
 * - CRISIL risk rating
 * - Fund star rating (1-5)
 * - Volatility
 * - Expense ratio
 * - AUM
 * - Returns (1W, 1Y, 3Y, 5Y)
 * - Fund manager
 */

const KUVERA_PROXY_URL = 'https://mf.captnemo.in/kuvera';
const KUVERA_API_BASE = 'https://api.kuvera.in/mf/api/v5/fund_schemes';

// Cache duration: 30 minutes (fund data updates less frequently)
const CACHE_DURATION = 30 * 60 * 1000;

// Rate limiting: max requests per second
const RATE_LIMIT_DELAY = 300; // ms between requests

export interface KuveraFundData {
  code: string;
  name: string;
  shortName: string;
  fundHouse: string;
  fundName: string;
  category: string;
  fundCategory: string;
  fundType: string;
  plan: string;
  isin: string;
  direct: string;
  maturityType: string;
  // Financial metrics
  nav: number;
  navDate: string;
  aum: number;
  expenseRatio: number;
  // Risk & Rating
  crisilRating: string;
  fundRating: number;
  volatility: number;
  // Returns
  returns: {
    week1?: number;
    month1?: number;
    month3?: number;
    month6?: number;
    year1?: number;
    year3?: number;
    year5?: number;
    inception?: number;
  };
  // Investment details
  sipAvailable: boolean;
  sipMin: number;
  sipMax: number;
  lumpAvailable: boolean;
  lumpMin: number;
  lumpMax: number;
  // Management
  fundManager: string;
}

export interface KuveraRiskData {
  isin: string;
  riskRating: number | null;       // 1-5 scale
  crisilRating: string | null;     // Original text
  volatility: number | null;       // Percentage
  fundRating?: number | null;      // Star rating 1-5
  expenseRatio?: number | null;
  aum?: number | null;
}

// CRISIL risk text to numeric mapping (1-5 scale)
const CRISIL_RISK_MAP: Record<string, number> = {
  'low': 1,
  'low risk': 1,
  'moderately low': 2,
  'moderately low risk': 2,
  'moderate': 3,
  'moderate risk': 3,
  'moderately high': 4,
  'moderately high risk': 4,
  'high': 5,
  'high risk': 5,
  'very high': 5,
  'very high risk': 5,
};

// Category-based risk mapping (fallback when API doesn't return data)
const CATEGORY_RISK_MAP: Record<string, { rating: number; text: string; volatility: number }> = {
  // Equity - Higher risk
  'small cap fund': { rating: 5, text: 'Very High Risk', volatility: 28 },
  'mid cap fund': { rating: 5, text: 'Very High Risk', volatility: 24 },
  'flexi cap fund': { rating: 4, text: 'Moderately High Risk', volatility: 18 },
  'multi cap fund': { rating: 4, text: 'Moderately High Risk', volatility: 18 },
  'large & mid cap fund': { rating: 4, text: 'Moderately High Risk', volatility: 17 },
  'large cap fund': { rating: 4, text: 'Moderately High Risk', volatility: 15 },
  'focused fund': { rating: 4, text: 'Moderately High Risk', volatility: 18 },
  'elss': { rating: 4, text: 'Moderately High Risk', volatility: 18 },
  'value fund': { rating: 4, text: 'Moderately High Risk', volatility: 17 },
  'contra fund': { rating: 4, text: 'Moderately High Risk', volatility: 17 },
  'dividend yield fund': { rating: 4, text: 'Moderately High Risk', volatility: 16 },
  'sectoral/thematic': { rating: 5, text: 'Very High Risk', volatility: 25 },
  // Hybrid - Moderate risk
  'aggressive hybrid fund': { rating: 4, text: 'Moderately High Risk', volatility: 14 },
  'balanced advantage fund': { rating: 3, text: 'Moderate Risk', volatility: 11 },
  'multi asset allocation fund': { rating: 3, text: 'Moderate Risk', volatility: 10 },
  'equity savings fund': { rating: 3, text: 'Moderate Risk', volatility: 8 },
  'conservative hybrid fund': { rating: 2, text: 'Moderately Low Risk', volatility: 6 },
  'arbitrage fund': { rating: 2, text: 'Moderately Low Risk', volatility: 3 },
  // Debt - Lower risk
  'credit risk fund': { rating: 3, text: 'Moderate Risk', volatility: 5 },
  'dynamic bond fund': { rating: 3, text: 'Moderate Risk', volatility: 5 },
  'medium to long duration fund': { rating: 3, text: 'Moderate Risk', volatility: 5 },
  'long duration fund': { rating: 3, text: 'Moderate Risk', volatility: 6 },
  'gilt fund': { rating: 3, text: 'Moderate Risk', volatility: 5 },
  'gilt fund with 10 year constant duration': { rating: 3, text: 'Moderate Risk', volatility: 6 },
  'medium duration fund': { rating: 2, text: 'Moderately Low Risk', volatility: 4 },
  'short duration fund': { rating: 2, text: 'Moderately Low Risk', volatility: 3 },
  'corporate bond fund': { rating: 2, text: 'Moderately Low Risk', volatility: 3 },
  'banking and psu fund': { rating: 2, text: 'Moderately Low Risk', volatility: 3 },
  'floater fund': { rating: 2, text: 'Moderately Low Risk', volatility: 2 },
  'low duration fund': { rating: 2, text: 'Moderately Low Risk', volatility: 2 },
  'ultra short duration fund': { rating: 1, text: 'Low Risk', volatility: 1.5 },
  'money market fund': { rating: 1, text: 'Low Risk', volatility: 1 },
  'liquid fund': { rating: 1, text: 'Low Risk', volatility: 0.5 },
  'overnight fund': { rating: 1, text: 'Low Risk', volatility: 0.3 },
  // Gold
  'gold': { rating: 3, text: 'Moderate Risk', volatility: 12 },
  'gold etf': { rating: 3, text: 'Moderate Risk', volatility: 12 },
  // International
  'international': { rating: 5, text: 'Very High Risk', volatility: 22 },
  'fund of funds (overseas)': { rating: 5, text: 'Very High Risk', volatility: 22 },
};

@Injectable()
export class KuveraService {
  private readonly logger = new Logger(KuveraService.name);

  // Cache for fund data
  private fundCache = new Map<string, { data: KuveraFundData; timestamp: number }>();
  private riskCache = new Map<string, { data: KuveraRiskData; timestamp: number }>();

  // Track last request time for rate limiting
  private lastRequestTime = 0;

  /**
   * Fetch full fund data from Kuvera API by ISIN
   */
  async getFundByIsin(isin: string): Promise<KuveraFundData | null> {
    if (!isin) return null;

    // Check cache
    const cached = this.fundCache.get(isin);
    if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
      return cached.data;
    }

    try {
      // Rate limiting
      await this.rateLimit();

      // First, get the redirect URL from mf.captnemo.in
      const proxyUrl = `${KUVERA_PROXY_URL}/${isin}`;
      const response = await fetch(proxyUrl, {
        redirect: 'follow',
        headers: {
          'Accept': 'application/json',
        },
      });

      if (!response.ok) {
        if (response.status === 404) {
          this.logger.debug(`Fund not found in Kuvera: ${isin}`);
          return null;
        }
        throw new Error(`Kuvera API returned ${response.status}`);
      }

      const data = await response.json();

      // Parse the response into our format
      const fundData = this.parseKuveraResponse(data, isin);

      if (fundData) {
        this.fundCache.set(isin, { data: fundData, timestamp: Date.now() });
      }

      return fundData;
    } catch (error) {
      this.logger.warn(`Failed to fetch from Kuvera for ${isin}: ${error.message}`);
      return null;
    }
  }

  /**
   * Parse Kuvera API response into our format
   * Note: Kuvera API can return either a single object or an array
   */
  private parseKuveraResponse(data: any, isin: string): KuveraFundData | null {
    // Handle array response (Kuvera returns array for some endpoints)
    const fund = Array.isArray(data) ? data[0] : data;

    if (!fund || !fund.code) {
      return null;
    }

    // Parse NAV - can be object or number
    let navValue = 0;
    if (typeof fund.nav === 'object' && fund.nav !== null) {
      navValue = parseFloat(fund.nav.nav) || 0;
    } else {
      navValue = parseFloat(fund.nav) || 0;
    }

    // Parse returns object
    const returns = fund.returns || {};

    return {
      code: fund.code,
      name: fund.name || '',
      shortName: fund.short_name || '',
      fundHouse: fund.fund_house || '',
      fundName: fund.fund_name || '',
      category: fund.category || '',
      fundCategory: fund.fund_category || '',
      fundType: fund.fund_type || '',
      plan: fund.plan || '',
      isin: fund.ISIN || isin,
      direct: fund.direct || 'N',
      maturityType: fund.maturity_type || '',
      // Financial metrics
      nav: navValue,
      navDate: fund.nav_date || (typeof fund.nav === 'object' ? fund.nav.date : ''),
      aum: parseFloat(fund.aum) || 0,
      expenseRatio: parseFloat(fund.expense_ratio) || 0,
      // Risk & Rating
      crisilRating: fund.crisil_rating || '',
      fundRating: parseInt(fund.fund_rating) || 0,
      volatility: parseFloat(fund.volatility) || 0,
      // Returns (Kuvera uses '1_week', '1_year' format)
      returns: {
        week1: returns['1_week'] != null ? parseFloat(returns['1_week']) : undefined,
        month1: returns['1_month'] != null ? parseFloat(returns['1_month']) : undefined,
        month3: returns['3_month'] != null ? parseFloat(returns['3_month']) : undefined,
        month6: returns['6_month'] != null ? parseFloat(returns['6_month']) : undefined,
        year1: returns['1_year'] != null ? parseFloat(returns['1_year']) : undefined,
        year3: returns['3_year'] != null ? parseFloat(returns['3_year']) : undefined,
        year5: returns['5_year'] != null ? parseFloat(returns['5_year']) : undefined,
        inception: returns.inception != null ? parseFloat(returns.inception) : undefined,
      },
      // Investment details
      sipAvailable: fund.sip_available === 'Y',
      sipMin: parseFloat(fund.sip_min) || 500,
      sipMax: parseFloat(fund.sip_max) || 999999999,
      lumpAvailable: fund.lump_available === 'Y',
      lumpMin: parseFloat(fund.lump_min) || 5000,
      lumpMax: parseFloat(fund.lump_max) || 999999999,
      // Management
      fundManager: fund.fund_manager || '',
    };
  }

  /**
   * Convert CRISIL text rating to numeric 1-5 scale
   */
  private mapCrisilToRating(crisilText: string | undefined): number | null {
    if (!crisilText) return null;
    const normalized = crisilText.toLowerCase().trim();
    return CRISIL_RISK_MAP[normalized] ?? null;
  }

  /**
   * Get risk data based on fund category (fallback)
   */
  getRiskFromCategory(category: string): { rating: number; text: string; volatility: number } | null {
    if (!category) return null;

    const normalized = category.toLowerCase().trim();

    // Try exact match first
    if (CATEGORY_RISK_MAP[normalized]) {
      return CATEGORY_RISK_MAP[normalized];
    }

    // Try partial match
    for (const [key, value] of Object.entries(CATEGORY_RISK_MAP)) {
      if (normalized.includes(key) || key.includes(normalized)) {
        return value;
      }
    }

    // Default based on keywords
    if (normalized.includes('small') || normalized.includes('micro')) {
      return { rating: 5, text: 'Very High Risk', volatility: 28 };
    }
    if (normalized.includes('mid')) {
      return { rating: 5, text: 'Very High Risk', volatility: 24 };
    }
    if (normalized.includes('equity') || normalized.includes('cap')) {
      return { rating: 4, text: 'Moderately High Risk', volatility: 18 };
    }
    if (normalized.includes('hybrid') || normalized.includes('balanced')) {
      return { rating: 3, text: 'Moderate Risk', volatility: 10 };
    }
    if (normalized.includes('debt') || normalized.includes('bond')) {
      return { rating: 2, text: 'Moderately Low Risk', volatility: 4 };
    }
    if (normalized.includes('liquid') || normalized.includes('money') || normalized.includes('overnight')) {
      return { rating: 1, text: 'Low Risk', volatility: 1 };
    }

    return null;
  }

  /**
   * Get risk rating for a single fund by ISIN
   * First tries Kuvera API, then falls back to category-based mapping
   */
  async getRiskRating(isin: string, category?: string): Promise<KuveraRiskData | null> {
    if (!isin && !category) {
      return null;
    }

    const cacheKey = isin || category || '';

    // Check cache
    const cached = this.riskCache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
      return cached.data;
    }

    // Try fetching from Kuvera API first
    if (isin) {
      const kuveraData = await this.getFundByIsin(isin);
      if (kuveraData) {
        const riskRating = this.mapCrisilToRating(kuveraData.crisilRating);
        const riskData: KuveraRiskData = {
          isin,
          riskRating: riskRating,
          crisilRating: kuveraData.crisilRating || null,
          volatility: kuveraData.volatility || null,
          fundRating: kuveraData.fundRating || null,
          expenseRatio: kuveraData.expenseRatio || null,
          aum: kuveraData.aum || null,
        };
        this.riskCache.set(cacheKey, { data: riskData, timestamp: Date.now() });
        return riskData;
      }
    }

    // Fallback to category-based mapping
    if (category) {
      const categoryRisk = this.getRiskFromCategory(category);
      if (categoryRisk) {
        const riskData: KuveraRiskData = {
          isin: isin || '',
          riskRating: categoryRisk.rating,
          crisilRating: categoryRisk.text,
          volatility: categoryRisk.volatility,
        };
        this.riskCache.set(cacheKey, { data: riskData, timestamp: Date.now() });
        return riskData;
      }
    }

    return null;
  }

  /**
   * Batch fetch risk ratings for multiple funds
   */
  async getRiskRatingsBatch(
    funds: Array<{ isin: string; category?: string }>
  ): Promise<Map<string, KuveraRiskData>> {
    const results = new Map<string, KuveraRiskData>();

    // Process in smaller batches to avoid overwhelming the API
    const batchSize = 3;
    for (let i = 0; i < funds.length; i += batchSize) {
      const batch = funds.slice(i, i + batchSize);

      const batchPromises = batch.map(async (fund) => {
        if (!fund.isin) return null;
        const riskData = await this.getRiskRating(fund.isin, fund.category);
        if (riskData) {
          results.set(fund.isin, riskData);
        }
        return riskData;
      });

      await Promise.allSettled(batchPromises);

      // Small delay between batches
      if (i + batchSize < funds.length) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }

    return results;
  }

  /**
   * Rate limiting helper
   */
  private async rateLimit(): Promise<void> {
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;

    if (timeSinceLastRequest < RATE_LIMIT_DELAY) {
      await new Promise(resolve => setTimeout(resolve, RATE_LIMIT_DELAY - timeSinceLastRequest));
    }

    this.lastRequestTime = Date.now();
  }

  /**
   * Clear cache (useful for testing or forced refresh)
   */
  clearCache(): void {
    this.fundCache.clear();
    this.riskCache.clear();
  }
}
