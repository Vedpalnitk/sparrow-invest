"""
Portfolio analysis schemas for current holdings analysis and rebalancing.
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Literal
from datetime import date


class PortfolioHoldingInput(BaseModel):
    """Input for a single portfolio holding."""

    scheme_code: int = Field(..., description="Fund scheme code")
    scheme_name: Optional[str] = Field(None, description="Fund name (auto-fetched if missing)")

    # Value input (one of two methods)
    amount: Optional[float] = Field(None, ge=0, description="Current value in INR")
    units: Optional[float] = Field(None, ge=0, description="Number of units held")

    # Tax tracking (optional)
    purchase_date: Optional[date] = Field(None, description="Date of purchase (ISO format)")
    purchase_price: Optional[float] = Field(None, ge=0, description="Cost basis per unit")
    purchase_amount: Optional[float] = Field(None, ge=0, description="Original investment amount")

    class Config:
        json_schema_extra = {
            "example": {
                "scheme_code": 120503,
                "amount": 500000,
                "purchase_date": "2024-01-15",
                "purchase_amount": 400000,
            }
        }


class AllocationTarget(BaseModel):
    """Target allocation percentages by asset class."""

    equity: float = Field(0.0, ge=0, le=1, description="Target equity allocation")
    debt: float = Field(0.0, ge=0, le=1, description="Target debt allocation")
    hybrid: float = Field(0.0, ge=0, le=1, description="Target hybrid allocation")
    gold: float = Field(0.0, ge=0, le=1, description="Target gold allocation")
    international: float = Field(0.0, ge=0, le=1, description="Target international allocation")
    liquid: float = Field(0.0, ge=0, le=1, description="Target liquid allocation")


class PortfolioAnalysisRequest(BaseModel):
    """Request for portfolio analysis against target allocation."""

    request_id: Optional[str] = Field(None, description="Request ID for tracking")
    holdings: List[PortfolioHoldingInput] = Field(..., min_length=1, description="Current portfolio holdings")
    target_allocation: AllocationTarget = Field(..., description="Target allocation from persona classification")
    profile: Dict = Field(..., description="User profile data")

    class Config:
        json_schema_extra = {
            "example": {
                "request_id": "analysis-123",
                "holdings": [
                    {"scheme_code": 120503, "amount": 500000, "purchase_date": "2024-01-15", "purchase_amount": 400000},
                    {"scheme_code": 119598, "amount": 300000, "purchase_date": "2023-06-01", "purchase_amount": 280000},
                    {"scheme_code": 120586, "amount": 200000, "purchase_date": "2025-10-01", "purchase_amount": 195000},
                ],
                "target_allocation": {
                    "equity": 0.40,
                    "debt": 0.35,
                    "hybrid": 0.15,
                    "gold": 0.05,
                    "international": 0.05,
                    "liquid": 0.00,
                },
                "profile": {
                    "risk_tolerance": "Moderate",
                    "horizon_years": 7,
                },
            }
        }


class EnrichedHolding(BaseModel):
    """Enriched holding with current data and tax info."""

    scheme_code: int
    scheme_name: str
    category: str
    asset_class: str
    current_value: float
    weight: float = Field(..., ge=0, le=1, description="Weight in portfolio (0-1)")
    units: Optional[float] = None
    nav: Optional[float] = None
    return_1y: Optional[float] = None
    return_3y: Optional[float] = None
    volatility: Optional[float] = None
    sharpe_ratio: Optional[float] = None

    # Tax info
    holding_period_days: Optional[int] = None
    tax_status: Optional[Literal["LTCG", "STCG"]] = None
    purchase_amount: Optional[float] = None
    unrealized_gain: Optional[float] = None


class RebalancingAction(BaseModel):
    """A single rebalancing action (SELL/BUY/HOLD/ADD_NEW)."""

    action: Literal["SELL", "BUY", "HOLD", "ADD_NEW"] = Field(..., description="Action type")
    priority: Literal["HIGH", "MEDIUM", "LOW"] = Field(..., description="Action priority")

    # Fund details
    scheme_code: int
    scheme_name: str
    category: str
    asset_class: str

    # Current state
    current_value: Optional[float] = Field(None, ge=0)
    current_weight: Optional[float] = Field(None, ge=0, le=1)
    current_units: Optional[float] = Field(None, ge=0)

    # Target state
    target_value: float = Field(..., ge=0)
    target_weight: float = Field(..., ge=0, le=1)

    # Transaction
    transaction_amount: float = Field(..., description="Amount to transact (negative for SELL)")
    transaction_units: Optional[float] = None

    # Tax implications (for SELL actions)
    tax_status: Optional[Literal["LTCG", "STCG"]] = None
    holding_period_days: Optional[int] = None
    estimated_gain: Optional[float] = None
    tax_note: Optional[str] = None

    # Reasoning
    reason: str


class CurrentMetrics(BaseModel):
    """Current portfolio metrics."""

    total_value: float = Field(..., ge=0, description="Total portfolio value")
    total_holdings: int = Field(..., ge=0, description="Number of holdings")
    weighted_return_1y: Optional[float] = None
    weighted_return_3y: Optional[float] = None
    weighted_volatility: Optional[float] = None
    weighted_sharpe: Optional[float] = None
    category_breakdown: Dict[str, Dict] = Field(
        default_factory=dict,
        description="Breakdown by category with allocation, count, value"
    )


class AnalysisSummary(BaseModel):
    """Summary of portfolio analysis."""

    is_aligned: bool = Field(..., description="Whether portfolio is aligned with target")
    alignment_score: float = Field(..., ge=0, le=1, description="Alignment score (0-1)")
    primary_issues: List[str] = Field(default_factory=list, description="Key issues identified")
    total_sell_amount: float = Field(0, ge=0)
    total_buy_amount: float = Field(0, ge=0)
    net_transaction: float = Field(0, description="Net cash flow (negative = investment needed)")
    tax_impact_summary: str = Field("", description="Summary of tax implications")


class PortfolioAnalysisResponse(BaseModel):
    """Response from portfolio analysis."""

    request_id: Optional[str] = None

    # Allocation breakdown
    current_allocation: AllocationTarget
    target_allocation: AllocationTarget
    allocation_gaps: Dict[str, float] = Field(
        ..., description="Gap by asset class (positive = overweight)"
    )

    # Current portfolio metrics
    current_metrics: CurrentMetrics

    # Enriched holdings
    holdings: List[EnrichedHolding]

    # Rebalancing actions
    rebalancing_actions: List[RebalancingAction]

    # Summary
    summary: AnalysisSummary

    # Metadata
    model_version: str
    latency_ms: float

    class Config:
        json_schema_extra = {
            "example": {
                "request_id": "analysis-123",
                "current_allocation": {
                    "equity": 1.0,
                    "debt": 0,
                    "hybrid": 0,
                    "gold": 0,
                    "international": 0,
                    "liquid": 0,
                },
                "target_allocation": {
                    "equity": 0.40,
                    "debt": 0.35,
                    "hybrid": 0.15,
                    "gold": 0.05,
                    "international": 0.05,
                    "liquid": 0.00,
                },
                "allocation_gaps": {
                    "equity": 0.60,
                    "debt": -0.35,
                    "hybrid": -0.15,
                    "gold": -0.05,
                    "international": -0.05,
                    "liquid": 0,
                },
                "current_metrics": {
                    "total_value": 1000000,
                    "total_holdings": 3,
                    "weighted_return_3y": 22.5,
                    "weighted_volatility": 16.8,
                },
                "holdings": [],
                "rebalancing_actions": [],
                "summary": {
                    "is_aligned": False,
                    "alignment_score": 0.40,
                    "primary_issues": ["100% equity concentration (target: 40%)"],
                    "total_sell_amount": 600000,
                    "total_buy_amount": 600000,
                    "net_transaction": 0,
                    "tax_impact_summary": "Estimated INR 12,000 LTCG tax",
                },
                "model_version": "portfolio-analyzer-v1",
                "latency_ms": 45,
            }
        }
