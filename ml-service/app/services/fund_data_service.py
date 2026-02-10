"""
Fund data service that fetches fund data from the Backend database.
The Backend syncs from MFAPI.in and stores in SchemePlan table.
This service fetches from Backend's /api/v1/funds/live/ml/funds endpoint.
"""

import httpx
import asyncio
import logging
import os
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass

logger = logging.getLogger(__name__)

# Backend URL - the source of truth for fund data
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:3501")

# Category to asset class mapping (kept for compatibility)
CATEGORY_TO_ASSET_CLASS = {
    # Equity categories
    "Large Cap": "equity",
    "Mid Cap": "equity",
    "Small Cap": "equity",
    "Flexi Cap": "equity",
    "Large & Mid Cap": "equity",
    "Multi Cap": "equity",
    "Focused": "equity",
    "ELSS": "equity",
    "Sectoral": "equity",
    "Thematic": "equity",
    "Index": "equity",
    "Contra": "equity",
    "Value": "equity",
    "Dividend Yield": "equity",
    "Equity": "equity",
    # Debt categories
    "Liquid": "liquid",
    "Overnight": "liquid",
    "Ultra Short Duration": "debt",
    "Low Duration": "debt",
    "Short Duration": "debt",
    "Medium Duration": "debt",
    "Medium to Long Duration": "debt",
    "Long Duration": "debt",
    "Dynamic Bond": "debt",
    "Corporate Bond": "debt",
    "Credit Risk": "debt",
    "Banking & PSU": "debt",
    "Gilt": "debt",
    "10 Yr Gilt": "debt",
    "Floater": "debt",
    "Income": "debt",
    # Hybrid categories
    "Balanced Advantage": "hybrid",
    "Aggressive Hybrid": "hybrid",
    "Conservative Hybrid": "hybrid",
    "Dynamic Asset Allocation": "hybrid",
    "Multi Asset Allocation": "hybrid",
    "Multi Asset": "hybrid",
    "Equity Savings": "hybrid",
    "Arbitrage": "hybrid",
    # Alternative categories
    "Gold": "gold",
    "Gold ETF": "gold",
    "Silver": "gold",
    "FOF - International": "international",
    "International": "international",
    "Other": "equity",
}


@dataclass
class FundData:
    scheme_code: int
    scheme_name: str
    fund_house: str
    category: str
    nav: float
    return_1y: Optional[float] = None
    return_3y: Optional[float] = None
    return_5y: Optional[float] = None
    volatility: Optional[float] = None
    sharpe_ratio: Optional[float] = None
    expense_ratio: Optional[float] = None
    asset_class: str = "equity"
    last_updated: Optional[datetime] = None


class FundDataService:
    """Service to fetch fund data from Backend database."""

    def __init__(self):
        self._cache: Dict[int, FundData] = {}
        self._cache_expiry: Optional[datetime] = None
        self._cache_duration = timedelta(minutes=30)  # Cache for 30 minutes
        self._initialized = False

    async def initialize(self):
        """Initialize the fund data cache."""
        if not self._initialized:
            await self.refresh_all_funds()
            self._initialized = True

    async def get_fund(self, scheme_code: int) -> Optional[FundData]:
        """Get fund data by scheme code."""
        if scheme_code in self._cache:
            return self._cache[scheme_code]
        return None

    async def get_all_funds(self) -> List[FundData]:
        """Get all cached funds."""
        if not self._cache or self._is_cache_expired():
            await self.refresh_all_funds()
        return list(self._cache.values())

    def _is_cache_expired(self) -> bool:
        """Check if cache has expired."""
        if not self._cache_expiry:
            return True
        return datetime.now() > self._cache_expiry

    async def refresh_all_funds(self):
        """Refresh fund data from Backend database."""
        logger.info(f"Refreshing fund data from Backend: {BACKEND_URL}")

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.get(f"{BACKEND_URL}/api/v1/funds/live/ml/funds")
                response.raise_for_status()
                data = response.json()

                funds_list = data.get("funds", [])
                logger.info(f"Received {len(funds_list)} funds from Backend")

                # Clear and rebuild cache
                self._cache.clear()

                for fund_dict in funds_list:
                    try:
                        fund = FundData(
                            scheme_code=fund_dict.get("scheme_code", 0),
                            scheme_name=fund_dict.get("scheme_name", ""),
                            fund_house=fund_dict.get("fund_house", "Unknown"),
                            category=fund_dict.get("category", "Other"),
                            nav=fund_dict.get("nav", 0),
                            return_1y=fund_dict.get("return_1y"),
                            return_3y=fund_dict.get("return_3y"),
                            return_5y=fund_dict.get("return_5y"),
                            volatility=fund_dict.get("volatility"),
                            sharpe_ratio=fund_dict.get("sharpe_ratio"),
                            expense_ratio=fund_dict.get("expense_ratio"),
                            asset_class=fund_dict.get("asset_class", "equity"),
                            last_updated=datetime.now(),
                        )
                        if fund.scheme_code > 0:
                            self._cache[fund.scheme_code] = fund
                    except Exception as e:
                        logger.warning(f"Failed to parse fund: {e}")
                        continue

                self._cache_expiry = datetime.now() + self._cache_duration
                logger.info(f"Fund data refresh complete. Loaded {len(self._cache)} funds.")

        except httpx.HTTPError as e:
            logger.error(f"HTTP error fetching funds from Backend: {e}")
            # Keep existing cache if refresh fails
            if not self._cache:
                logger.warning("No cached data available, using fallback")
                self._load_fallback_funds()
        except Exception as e:
            logger.error(f"Error refreshing funds: {e}")
            if not self._cache:
                self._load_fallback_funds()

    def _load_fallback_funds(self):
        """Load fallback funds if backend is unavailable."""
        fallback = get_fallback_funds()
        for fund_dict in fallback:
            fund = FundData(
                scheme_code=fund_dict["scheme_code"],
                scheme_name=fund_dict["scheme_name"],
                fund_house=fund_dict["fund_house"],
                category=fund_dict["category"],
                nav=100.0,
                return_1y=fund_dict.get("return_1y"),
                return_3y=fund_dict.get("return_3y"),
                return_5y=fund_dict.get("return_5y"),
                volatility=fund_dict.get("volatility"),
                sharpe_ratio=fund_dict.get("sharpe_ratio"),
                expense_ratio=fund_dict.get("expense_ratio"),
                asset_class=CATEGORY_TO_ASSET_CLASS.get(fund_dict["category"], "equity"),
            )
            self._cache[fund.scheme_code] = fund
        self._cache_expiry = datetime.now() + timedelta(hours=1)
        logger.warning(f"Loaded {len(self._cache)} fallback funds")


# Singleton instance
fund_data_service = FundDataService()


def get_funds_as_dict_list() -> List[Dict]:
    """Get all funds as list of dicts (for compatibility with existing code)."""
    import asyncio

    # Get event loop or create one
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

    # If we're already in an async context, we can't use run_until_complete
    if fund_data_service._cache:
        funds = list(fund_data_service._cache.values())
    else:
        try:
            loop.run_until_complete(fund_data_service.refresh_all_funds())
            funds = list(fund_data_service._cache.values())
        except RuntimeError:
            logger.warning("Cannot fetch funds synchronously from async context. Using fallback.")
            return get_fallback_funds()

    return [
        {
            "scheme_code": f.scheme_code,
            "scheme_name": f.scheme_name,
            "fund_house": f.fund_house,
            "category": f.category,
            "asset_class": f.asset_class,
            "return_1y": f.return_1y or 0,
            "return_3y": f.return_3y or 0,
            "return_5y": f.return_5y or 0,
            "volatility": f.volatility or 15.0,
            "sharpe_ratio": f.sharpe_ratio or 0.8,
            "expense_ratio": f.expense_ratio or 0.5,
        }
        for f in funds
    ]


def get_fallback_funds() -> List[Dict]:
    """Fallback fund data in case Backend is unavailable."""
    return [
        {
            "scheme_code": 119598,
            "scheme_name": "Parag Parikh Flexi Cap Fund Direct Growth",
            "fund_house": "PPFAS Mutual Fund",
            "category": "Flexi Cap",
            "return_1y": 22.4,
            "return_3y": 18.7,
            "return_5y": 19.2,
            "volatility": 14.2,
            "sharpe_ratio": 1.1,
            "expense_ratio": 0.63,
        },
        {
            "scheme_code": 120503,
            "scheme_name": "Quant Flexi Cap Fund Direct Growth",
            "fund_house": "Quant Mutual Fund",
            "category": "Flexi Cap",
            "return_1y": 28.5,
            "return_3y": 24.3,
            "return_5y": 22.1,
            "volatility": 18.5,
            "sharpe_ratio": 1.2,
            "expense_ratio": 0.58,
        },
        {
            "scheme_code": 120586,
            "scheme_name": "ICICI Prudential Bluechip Fund Direct Growth",
            "fund_house": "ICICI Prudential Mutual Fund",
            "category": "Large Cap",
            "return_1y": 15.2,
            "return_3y": 14.8,
            "return_5y": 13.5,
            "volatility": 12.5,
            "sharpe_ratio": 0.9,
            "expense_ratio": 0.85,
        },
        {
            "scheme_code": 118531,
            "scheme_name": "Franklin India Large Cap Fund Direct Growth",
            "fund_house": "Franklin Templeton Mutual Fund",
            "category": "Large Cap",
            "return_1y": 12.8,
            "return_3y": 13.2,
            "return_5y": 12.1,
            "volatility": 13.1,
            "sharpe_ratio": 0.85,
            "expense_ratio": 0.95,
        },
        {
            "scheme_code": 120505,
            "scheme_name": "Axis Midcap Fund Direct Growth",
            "fund_house": "Axis Mutual Fund",
            "category": "Mid Cap",
            "return_1y": 18.5,
            "return_3y": 16.8,
            "return_5y": 15.2,
            "volatility": 15.8,
            "sharpe_ratio": 1.0,
            "expense_ratio": 0.52,
        },
    ]
