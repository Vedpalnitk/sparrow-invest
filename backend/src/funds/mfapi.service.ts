import { Injectable, Logger } from '@nestjs/common';
import { KuveraService } from './kuvera.service';

/**
 * MFAPI.in - Free Indian Mutual Fund API
 * Docs: https://www.mfapi.in/
 *
 * Endpoints:
 * - GET /mf - List all schemes (47000+ funds)
 * - GET /mf/search?q={query} - Search funds
 * - GET /mf/{schemeCode} - Get fund details with NAV history
 */

const MFAPI_BASE_URL = 'https://api.mfapi.in/mf';

// Cache duration in milliseconds
const CACHE_DURATION = 15 * 60 * 1000; // 15 minutes

export interface MFScheme {
  schemeCode: number;
  schemeName: string;
}

export interface MFNavData {
  date: string;
  nav: string;
}

export interface MFMeta {
  fund_house: string;
  scheme_type: string;
  scheme_category: string;
  scheme_code: number;
  scheme_name: string;
  isin_growth: string | null;
  isin_div_reinvestment: string | null;
}

export interface MFDetails {
  meta: MFMeta;
  data: MFNavData[];
  status: string;
}

export interface FundWithMetrics {
  schemeCode: number;
  schemeName: string;
  fundHouse: string;
  category: string;
  schemeType: string;
  currentNav: number;
  previousNav: number;
  dayChange: number;
  dayChangePercent: number;
  return1Y?: number;
  return3Y?: number;
  return5Y?: number;
  assetClass: string;
  // Risk data from Kuvera
  isin?: string;
  riskRating?: number;      // 1-5 scale
  crisilRating?: string;    // Original CRISIL text
  volatility?: number;      // Percentage
  // Additional Kuvera data
  fundRating?: number;      // Star rating 1-5
  expenseRatio?: number;    // TER percentage
  aum?: number;             // Assets Under Management in Crores
  fundManager?: string;     // Fund manager name
}

// Map categories to asset classes
const CATEGORY_TO_ASSET_CLASS: Record<string, string> = {
  // Equity
  'Large Cap Fund': 'equity',
  'Large & Mid Cap Fund': 'equity',
  'Mid Cap Fund': 'equity',
  'Small Cap Fund': 'equity',
  'Multi Cap Fund': 'equity',
  'Flexi Cap Fund': 'equity',
  'Focused Fund': 'equity',
  'ELSS': 'equity',
  'Value Fund': 'equity',
  'Contra Fund': 'equity',
  'Dividend Yield Fund': 'equity',
  'Sectoral/Thematic': 'equity',
  // Debt
  'Liquid Fund': 'liquid',
  'Ultra Short Duration Fund': 'debt',
  'Low Duration Fund': 'debt',
  'Short Duration Fund': 'debt',
  'Medium Duration Fund': 'debt',
  'Medium to Long Duration Fund': 'debt',
  'Long Duration Fund': 'debt',
  'Dynamic Bond Fund': 'debt',
  'Corporate Bond Fund': 'debt',
  'Credit Risk Fund': 'debt',
  'Banking and PSU Fund': 'debt',
  'Gilt Fund': 'debt',
  'Gilt Fund with 10 year constant duration': 'debt',
  'Floater Fund': 'debt',
  'Money Market Fund': 'liquid',
  'Overnight Fund': 'liquid',
  // Hybrid
  'Aggressive Hybrid Fund': 'hybrid',
  'Conservative Hybrid Fund': 'hybrid',
  'Balanced Advantage Fund': 'hybrid',
  'Multi Asset Allocation Fund': 'hybrid',
  'Arbitrage Fund': 'hybrid',
  'Equity Savings Fund': 'hybrid',
  // Gold
  'Gold': 'gold',
  'Gold ETF': 'gold',
  // International
  'International': 'international',
  'Fund of Funds (Overseas)': 'international',
};

@Injectable()
export class MfApiService {
  private readonly logger = new Logger(MfApiService.name);

  // Simple in-memory cache
  private cache = new Map<string, { data: any; timestamp: number }>();

  constructor(private readonly kuveraService: KuveraService) {}

  /**
   * Search for mutual funds by name
   */
  async searchFunds(query: string): Promise<MFScheme[]> {
    if (!query || query.length < 2) {
      return [];
    }

    const cacheKey = `search:${query.toLowerCase()}`;
    const cached = this.getFromCache<MFScheme[]>(cacheKey);
    if (cached) return cached;

    try {
      const response = await fetch(`${MFAPI_BASE_URL}/search?q=${encodeURIComponent(query)}`);

      if (!response.ok) {
        throw new Error(`MFAPI returned ${response.status}`);
      }

      const data = await response.json() as MFScheme[];
      this.setCache(cacheKey, data);

      return data;
    } catch (error) {
      this.logger.error(`Search failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get detailed fund information including NAV history
   */
  async getFundDetails(schemeCode: number): Promise<MFDetails> {
    const cacheKey = `fund:${schemeCode}`;
    const cached = this.getFromCache<MFDetails>(cacheKey);
    if (cached) return cached;

    try {
      const response = await fetch(`${MFAPI_BASE_URL}/${schemeCode}`);

      if (!response.ok) {
        if (response.status === 404) {
          throw new Error('Fund not found');
        }
        throw new Error(`MFAPI returned ${response.status}`);
      }

      const data = await response.json() as MFDetails;

      if (data.status !== 'SUCCESS') {
        throw new Error('Fund not found');
      }

      this.setCache(cacheKey, data);
      return data;
    } catch (error) {
      this.logger.error(`GetFundDetails failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get fund with calculated metrics (returns, volatility, etc.)
   * Fetches additional data from Kuvera API including ratings, expense ratio, AUM
   */
  async getFundWithMetrics(schemeCode: number): Promise<FundWithMetrics> {
    const details = await this.getFundDetails(schemeCode);

    const currentNavData = details.data[0];
    const previousNavData = details.data[1];

    const currentNav = parseFloat(currentNavData.nav);
    const previousNav = parseFloat(previousNavData.nav);
    const dayChange = currentNav - previousNav;
    const dayChangePercent = (dayChange / previousNav) * 100;

    // Extract category from scheme_category (format: "Equity Scheme - Large Cap Fund")
    const categoryParts = details.meta.scheme_category.split(' - ');
    const category = categoryParts.length > 1 ? categoryParts[1] : details.meta.scheme_category;

    // Calculate returns from NAV history
    const returns = this.calculateReturns(details.data);

    // Get ISIN (prefer growth ISIN)
    const isin = details.meta.isin_growth || details.meta.isin_div_reinvestment || undefined;

    // Fetch full data from Kuvera API using ISIN
    let riskRating: number | undefined;
    let crisilRating: string | undefined;
    let volatility: number | undefined;
    let fundRating: number | undefined;
    let expenseRatio: number | undefined;
    let aum: number | undefined;
    let fundManager: string | undefined;
    let kuveraReturns: { return1Y?: number; return3Y?: number; return5Y?: number } = {};

    if (isin) {
      try {
        // Try to get full fund data from Kuvera API
        const kuveraData = await this.kuveraService.getFundByIsin(isin);
        if (kuveraData) {
          // Map CRISIL text to numeric rating
          crisilRating = kuveraData.crisilRating || undefined;
          riskRating = this.mapCrisilToRating(crisilRating);
          volatility = kuveraData.volatility || undefined;
          fundRating = kuveraData.fundRating || undefined;
          expenseRatio = kuveraData.expenseRatio || undefined;
          aum = kuveraData.aum || undefined;
          fundManager = kuveraData.fundManager || undefined;

          // Use Kuvera returns if available (more accurate)
          if (kuveraData.returns) {
            kuveraReturns.return1Y = kuveraData.returns.year1;
            kuveraReturns.return3Y = kuveraData.returns.year3;
            kuveraReturns.return5Y = kuveraData.returns.year5;
          }
        }
      } catch (error) {
        this.logger.warn(`Failed to fetch Kuvera data for ${isin}: ${error.message}`);
      }
    }

    // Fallback to category-based risk if Kuvera didn't return data
    if (!riskRating && category) {
      const categoryRisk = this.kuveraService.getRiskFromCategory(category);
      if (categoryRisk) {
        riskRating = categoryRisk.rating;
        crisilRating = categoryRisk.text;
        volatility = categoryRisk.volatility;
      }
    }

    return {
      schemeCode: details.meta.scheme_code,
      schemeName: details.meta.scheme_name,
      fundHouse: details.meta.fund_house,
      category,
      schemeType: details.meta.scheme_type,
      currentNav,
      previousNav,
      dayChange,
      dayChangePercent,
      // Prefer Kuvera returns if available, otherwise use calculated returns
      return1Y: kuveraReturns.return1Y ?? returns.return1Y,
      return3Y: kuveraReturns.return3Y ?? returns.return3Y,
      return5Y: kuveraReturns.return5Y ?? returns.return5Y,
      assetClass: this.getAssetClass(category),
      isin,
      riskRating,
      crisilRating,
      volatility,
      fundRating,
      expenseRatio,
      aum,
      fundManager,
    };
  }

  /**
   * Map CRISIL text to numeric rating (1-5)
   */
  private mapCrisilToRating(crisilText: string | undefined): number | undefined {
    if (!crisilText) return undefined;

    const text = crisilText.toLowerCase().trim();
    if (text.includes('low') && !text.includes('moderate')) return 1;
    if (text.includes('moderately low')) return 2;
    if (text.includes('moderate') && !text.includes('high') && !text.includes('low')) return 3;
    if (text.includes('moderately high')) return 4;
    if (text.includes('high') || text.includes('very high')) return 5;

    return undefined;
  }

  /**
   * Get multiple funds in parallel (with rate limiting)
   * Uses batch Kuvera data fetching for efficiency
   */
  async getMultipleFunds(schemeCodes: number[]): Promise<FundWithMetrics[]> {
    // Process in batches to avoid overwhelming the API
    const batchSize = 5;
    const results: FundWithMetrics[] = [];

    for (let i = 0; i < schemeCodes.length; i += batchSize) {
      const batch = schemeCodes.slice(i, i + batchSize);
      const batchResults = await Promise.allSettled(
        batch.map(code => this.getFundDetailsOnly(code))
      );

      const fundsInBatch: FundWithMetrics[] = [];
      for (const result of batchResults) {
        if (result.status === 'fulfilled') {
          fundsInBatch.push(result.value);
        }
      }

      // Fetch Kuvera data for each fund with ISIN
      for (const fund of fundsInBatch) {
        if (fund.isin) {
          try {
            const kuveraData = await this.kuveraService.getFundByIsin(fund.isin);
            if (kuveraData) {
              // Update risk data
              fund.crisilRating = kuveraData.crisilRating || undefined;
              fund.riskRating = this.mapCrisilToRating(fund.crisilRating);
              fund.volatility = kuveraData.volatility || undefined;
              // Update additional data
              fund.fundRating = kuveraData.fundRating || undefined;
              fund.expenseRatio = kuveraData.expenseRatio || undefined;
              fund.aum = kuveraData.aum || undefined;
              fund.fundManager = kuveraData.fundManager || undefined;
              // Update returns from Kuvera if available
              if (kuveraData.returns) {
                fund.return1Y = kuveraData.returns.year1 ?? fund.return1Y;
                fund.return3Y = kuveraData.returns.year3 ?? fund.return3Y;
                fund.return5Y = kuveraData.returns.year5 ?? fund.return5Y;
              }
            }
          } catch (error) {
            this.logger.debug(`Failed to fetch Kuvera data for ${fund.isin}: ${error.message}`);
          }
        }

        // Fallback to category-based risk if no Kuvera data
        if (!fund.riskRating && fund.category) {
          const categoryRisk = this.kuveraService.getRiskFromCategory(fund.category);
          if (categoryRisk) {
            fund.riskRating = categoryRisk.rating;
            fund.crisilRating = categoryRisk.text;
            fund.volatility = categoryRisk.volatility;
          }
        }
      }

      results.push(...fundsInBatch);

      // Small delay between batches
      if (i + batchSize < schemeCodes.length) {
        await new Promise(resolve => setTimeout(resolve, 200));
      }
    }

    return results;
  }

  /**
   * Get fund details without risk data (used for batch processing)
   */
  private async getFundDetailsOnly(schemeCode: number): Promise<FundWithMetrics> {
    const details = await this.getFundDetails(schemeCode);

    const currentNavData = details.data[0];
    const previousNavData = details.data[1];

    const currentNav = parseFloat(currentNavData.nav);
    const previousNav = parseFloat(previousNavData.nav);
    const dayChange = currentNav - previousNav;
    const dayChangePercent = (dayChange / previousNav) * 100;

    const categoryParts = details.meta.scheme_category.split(' - ');
    const category = categoryParts.length > 1 ? categoryParts[1] : details.meta.scheme_category;

    const returns = this.calculateReturns(details.data);
    const isin = details.meta.isin_growth || details.meta.isin_div_reinvestment || undefined;

    return {
      schemeCode: details.meta.scheme_code,
      schemeName: details.meta.scheme_name,
      fundHouse: details.meta.fund_house,
      category,
      schemeType: details.meta.scheme_type,
      currentNav,
      previousNav,
      dayChange,
      dayChangePercent,
      return1Y: returns.return1Y,
      return3Y: returns.return3Y,
      return5Y: returns.return5Y,
      assetClass: this.getAssetClass(category),
      isin,
    };
  }

  /**
   * Get popular/recommended funds - Curated list of ~150 top funds across categories
   * Smaller list for faster API response; use getFundsByCategory for full lists
   */
  async getPopularFunds(): Promise<FundWithMetrics[]> {
    // Curated list of top Direct Growth funds across categories (~150 funds)
    const popularCodes = [
      // ============= LARGE CAP (10 funds) =============
      120586, 118531, 119308, 120465, 120490, 118479, 118641, 119148, 119528, 120656,

      // ============= LARGE & MID CAP (8 funds) =============
      118510, 119350, 120596, 120665, 118834, 119202, 120158, 130498,

      // ============= FLEXI CAP (10 funds) =============
      120564, 120166, 119291, 120492, 118883, 120662, 120757, 118535, 120046, 120843,

      // ============= MULTI CAP (8 funds) =============
      118650, 119354, 120413, 120599, 119451, 118651, 119464, 131164,

      // ============= MID CAP (10 funds) =============
      120505, 119807, 118533, 119071, 120381, 120726, 119909, 118665, 120002, 125307,

      // ============= SMALL CAP (10 funds) =============
      120591, 120828, 118525, 119589, 119869, 120069, 120164, 120077, 125354, 130503,

      // ============= ELSS / TAX SAVER (8 funds) =============
      120503, 119871, 120079, 119773, 118540, 120592, 118946, 120494,

      // ============= FOCUSED (6 funds) =============
      120488, 120722, 118564, 119564, 120834, 127919,

      // ============= VALUE / CONTRA (6 funds) =============
      120699, 120751, 119231, 120386, 118784, 119404,

      // ============= SECTORAL - BANKING & FINANCIAL (5 funds) =============
      118588, 120244, 120733, 134017, 143353,

      // ============= SECTORAL - IT & TECHNOLOGY (5 funds) =============
      118758, 120782, 143783, 145454, 147409,

      // ============= SECTORAL - INFRASTRUCTURE (5 funds) =============
      118469, 118762, 118773, 118879, 119243,

      // ============= BALANCED ADVANTAGE (8 funds) =============
      120377, 120679, 118543, 119298, 120042, 120088, 134110, 134150,

      // ============= AGGRESSIVE HYBRID (6 funds) =============
      120484, 120674, 118546, 119019, 120261, 125711,

      // ============= CONSERVATIVE HYBRID (5 funds) =============
      120073, 120082, 118726, 119156, 119389,

      // ============= EQUITY SAVINGS (4 funds) =============
      120156, 120355, 119789, 120571,

      // ============= ARBITRAGE (4 funds) =============
      120179, 120421, 119224, 119501,

      // ============= MULTI ASSET ALLOCATION (5 funds) =============
      120160, 120524, 120760, 119208, 119572,

      // ============= CORPORATE BOND (6 funds) =============
      120497, 120692, 118807, 119104, 119479, 133791,

      // ============= BANKING & PSU (6 funds) =============
      120256, 120338, 120438, 119625, 119795, 121268,

      // ============= SHORT DURATION (6 funds) =============
      120458, 120510, 120525, 118796, 119379, 120541,

      // ============= LIQUID (6 funds) =============
      120104, 120123, 118610, 118636, 119091, 119303,

      // ============= OVERNIGHT (4 funds) =============
      120557, 120785, 145536, 145810,

      // ============= GOLD (5 funds) =============
      120531, 120685, 118604, 119344, 120000,

      // ============= INDEX - NIFTY 50 (6 funds) =============
      120307, 120716, 118482, 118741, 141877, 146376,

      // ============= INDEX - SENSEX (3 funds) =============
      118791, 120306, 120308,

      // ============= INTERNATIONAL (5 funds) =============
      118518, 118742, 118770, 119271, 120043,
    ];

    return this.getMultipleFunds(popularCodes);
  }

  /**
   * Get funds by category - Expanded lists
   */
  async getFundsByCategory(category: string, limit: number = 30): Promise<FundWithMetrics[]> {
    const categoryFundCodes: Record<string, number[]> = {
      'large_cap': [
        118479, 118531, 118617, 118632, 118633, 118641, 118643, 118825, 118870, 119018,
        119148, 119160, 119250, 119308, 119367, 119528, 119893, 119914, 120030, 120100,
        120152, 120267, 120465, 120490, 120586, 120656, 134001, 134134, 134413, 138312,
      ],
      'large_mid_cap': [
        118419, 118510, 118675, 118678, 118834, 119202, 119218, 119350, 119397, 119436,
        119566, 120158, 120357, 120596, 120665, 120826, 130498, 133710, 135677, 140175,
        145110, 146772, 147704, 147750, 147840,
      ],
      'mid_cap': [
        118533, 118665, 118668, 118872, 118989, 119071, 119178, 119182, 119581, 119620,
        119775, 119807, 119909, 120002, 120297, 120381, 120403, 120505, 120726, 120841,
        125307, 127042, 133144, 138950, 140228, 140461, 141950, 142110, 144315, 147445,
      ],
      'small_cap': [
        118525, 118777, 118778, 119212, 119556, 119589, 119869, 120069, 120077, 120164,
        120591, 120828, 125354, 125497, 129649, 130503, 132985, 134297, 134373, 141475,
        141499, 141561, 142533, 143010, 143226, 143506, 144437, 144728, 144988, 145137,
      ],
      'flexi_cap': [
        118424, 118535, 118883, 118955, 119076, 119291, 119292, 120046, 120166, 120264,
        120492, 120564, 120662, 120757, 120843, 122639, 128236, 129046, 133839, 140353,
        141925, 143793, 144546, 144905, 148404, 148642, 148990, 149094, 149104, 149450,
      ],
      'multi_cap': [
        118650, 118651, 119354, 119451, 119452, 119464, 119988, 120413, 120599, 131164,
        141226, 143828, 144200, 147183, 149185, 149368, 149383, 149533, 149668, 149669,
        149882, 150659, 150858, 151232, 151290,
      ],
      'elss': [
        111549, 118473, 118540, 118620, 118803, 118866, 118946, 119060, 119242, 119307,
        119351, 119417, 119544, 119661, 119773, 119871, 119916, 120079, 120147, 120270,
        120416, 120494, 120503, 120592, 120715, 120847, 126279, 131739, 132756, 133324,
      ],
      'focused': [
        118421, 118564, 118692, 118927, 118950, 119096, 119564, 120468, 120488, 120722,
        120834, 122389, 126639, 127919, 131526, 131580, 133105, 133529, 133897, 134334,
        135351, 141813, 141920, 145376, 147206,
      ],
      'value': [
        103490, 118481, 118494, 118784, 118935, 119231, 119323, 119404, 119549, 119659,
        119769, 120323, 120348, 120386, 120486, 120699, 120751, 120759, 123012, 133320,
      ],
      'hybrid': [
        118543, 118615, 118736, 118737, 118968, 119298, 119482, 120042, 120088, 120333,
        120377, 120679, 126393, 131355, 134110, 118485, 118546, 118624, 118794, 119019,
        119053, 120261, 120484, 120674, 120819, 118486, 118491, 118726, 119156, 119389,
      ],
      'balanced_advantage': [
        118543, 118615, 118736, 118737, 118968, 119298, 119482, 120042, 120088, 120333,
        120377, 120679, 126393, 131355, 134110, 134150, 139872, 140357, 141642, 142038,
        144335, 145396, 146010, 147406, 148026,
      ],
      'arbitrage': [
        118561, 118735, 119224, 119501, 119700, 120179, 120421, 120680, 133727, 145012,
      ],
      'debt': [
        118807, 118814, 118987, 119104, 119479, 119621, 119984, 120497, 120692, 133791,
        119625, 119795, 120256, 120338, 120438, 120444, 121268, 121279, 123693, 123905,
        118407, 118796, 119379, 119400, 120062, 120458, 120510, 120525, 120541, 120560,
      ],
      'corporate_bond': [
        118807, 118814, 118987, 119104, 119479, 119621, 119984, 120497, 120692, 133791,
        135916, 138330, 140333, 141588, 143241, 144339, 144646, 146215, 147389, 148492,
      ],
      'banking_psu': [
        119625, 119795, 120256, 120338, 120438, 120444, 121268, 121279, 123693, 123905,
        124175, 125503, 126940, 128629, 129008, 134363, 134547, 134552, 138564, 140286,
      ],
      'gilt': [
        118297, 118341, 118427, 118464, 118631, 118672, 118887, 119054, 119099, 119114,
        119116, 119341, 119425, 119603, 119757, 119759, 119762, 119859, 119944, 119966,
      ],
      'liquid': [
        103734, 118345, 118364, 118610, 118636, 118701, 118857, 118859, 118893, 119091,
        119135, 119164, 119173, 119181, 119303, 119360, 119369, 119766, 119790, 119861,
        119905, 120038, 120104, 120123, 120197,
      ],
      'overnight': [
        119110, 119283, 120557, 120785, 145536, 145810, 146062, 146141, 146191, 146675,
        146963, 146980, 147003, 147125, 147196, 147214, 147287, 147450, 147515, 147564,
      ],
      'money_market': [
        118384, 118506, 118715, 118719, 119092, 119424, 119431, 119746, 120211, 120507,
        120845, 140237, 143597, 145050, 147377,
      ],
      'index': [
        118347, 118482, 118581, 118741, 120307, 120716, 141877, 146376, 147794, 148360,
        118791, 120306, 120308, 149803, 151769, 152422, 129725, 148726, 148807, 149343,
        148519, 148815, 149283, 149894, 150677, 118266, 118348, 118545, 120684, 126455,
      ],
      'sectoral': [
        118588, 118589, 118868, 119333, 120244, 120733, 125597, 134017, 135793, 143353,
        118758, 118759, 120782, 135810, 143783, 145454, 146517, 147409, 148555, 149268,
        118469, 118762, 118763, 118773, 118774, 118722, 118724, 118837, 119595, 120587,
      ],
      'banking': [
        118588, 118589, 118868, 119333, 120244, 120733, 125597, 134017, 135793, 143353,
        148623, 148986, 149321, 151384, 152206,
      ],
      'pharma': [
        118758, 118759, 120782, 135810, 143783, 145454, 146517, 147409, 148555, 149268,
        150930, 151853, 152024, 152082, 152214,
      ],
      'infrastructure': [
        118469, 118762, 118763, 118773, 118774, 118879, 118979, 119243, 119259, 119269,
        119273, 119343, 119364, 119413, 120351,
      ],
      'international': [
        102987, 118518, 118519, 118742, 118770, 118785, 118831, 118874, 118876, 118881,
        118885, 118889, 118958, 119000, 119271, 119420, 119578, 119977, 120017, 120027,
        120043, 120340, 120345, 120461, 133115,
      ],
      'gold': [
        115132, 118301, 118604, 118606, 118663, 119344, 119781, 120000, 120473, 120531,
        120685, 133816, 150581, 150714, 151974,
      ],
      'retirement': [
        118548, 119251, 119255, 119256, 133568, 133569, 135749, 135751, 135753, 136465,
      ],
      'children': [
        118521, 118523, 119312, 120285, 135762, 135764, 148490, 152219,
      ],
    };

    const codes = categoryFundCodes[category.toLowerCase()] || [];
    return this.getMultipleFunds(codes.slice(0, limit));
  }

  /**
   * Search and get funds by category
   */
  async searchByCategory(category: string, limit: number = 10): Promise<MFScheme[]> {
    const results = await this.searchFunds(category);

    // Filter for Direct Growth plans only
    const directGrowth = results.filter(fund =>
      fund.schemeName.includes('Direct') &&
      fund.schemeName.includes('Growth')
    );

    return directGrowth.slice(0, limit);
  }

  // ============= Private Helpers =============

  private calculateReturns(navData: MFNavData[]): { return1Y?: number; return3Y?: number; return5Y?: number } {
    if (navData.length < 2) {
      return {};
    }

    const currentNav = parseFloat(navData[0].nav);
    const currentDate = this.parseNavDate(navData[0].date);

    const getDateAgo = (months: number): Date => {
      const date = new Date(currentDate);
      date.setMonth(date.getMonth() - months);
      return date;
    };

    const findNavByDate = (targetDate: Date): number | null => {
      const targetTime = targetDate.getTime();

      for (const nav of navData) {
        const navDate = this.parseNavDate(nav.date);
        const diff = Math.abs(navDate.getTime() - targetTime);

        // Within 7 days (to handle weekends/holidays)
        if (diff <= 7 * 24 * 60 * 60 * 1000) {
          return parseFloat(nav.nav);
        }
      }
      return null;
    };

    const calculateCAGR = (pastNav: number, years: number): number => {
      if (pastNav <= 0 || years <= 0) return 0;
      return (Math.pow(currentNav / pastNav, 1 / years) - 1) * 100;
    };

    const nav1Y = findNavByDate(getDateAgo(12));
    const nav3Y = findNavByDate(getDateAgo(36));
    const nav5Y = findNavByDate(getDateAgo(60));

    return {
      return1Y: nav1Y ? calculateCAGR(nav1Y, 1) : undefined,
      return3Y: nav3Y ? calculateCAGR(nav3Y, 3) : undefined,
      return5Y: nav5Y ? calculateCAGR(nav5Y, 5) : undefined,
    };
  }

  private parseNavDate(dateStr: string): Date {
    // Format: DD-MM-YYYY
    const [day, month, year] = dateStr.split('-').map(Number);
    return new Date(year, month - 1, day);
  }

  private getAssetClass(category: string): string {
    // Try exact match
    if (CATEGORY_TO_ASSET_CLASS[category]) {
      return CATEGORY_TO_ASSET_CLASS[category];
    }

    // Try partial match
    for (const [key, value] of Object.entries(CATEGORY_TO_ASSET_CLASS)) {
      if (category.toLowerCase().includes(key.toLowerCase())) {
        return value;
      }
    }

    // Default based on keywords
    const lower = category.toLowerCase();
    if (lower.includes('equity') || lower.includes('cap')) return 'equity';
    if (lower.includes('debt') || lower.includes('bond') || lower.includes('gilt')) return 'debt';
    if (lower.includes('liquid') || lower.includes('money') || lower.includes('overnight')) return 'liquid';
    if (lower.includes('hybrid') || lower.includes('balanced')) return 'hybrid';
    if (lower.includes('gold')) return 'gold';
    if (lower.includes('international') || lower.includes('overseas') || lower.includes('global')) return 'international';

    return 'equity'; // Default
  }

  private getFromCache<T>(key: string): T | null {
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
      return cached.data as T;
    }
    return null;
  }

  private setCache(key: string, data: any): void {
    this.cache.set(key, { data, timestamp: Date.now() });

    // Cleanup old entries if cache gets too large
    if (this.cache.size > 1000) {
      const now = Date.now();
      for (const [k, v] of this.cache.entries()) {
        if (now - v.timestamp > CACHE_DURATION) {
          this.cache.delete(k);
        }
      }
    }
  }
}
