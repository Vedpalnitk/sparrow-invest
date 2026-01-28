"""
Portfolio Analysis Service

Analyzes current portfolio holdings against target allocation from persona classification.
Generates a detailed rebalancing roadmap with tax awareness.
"""

import logging
import time
from datetime import date, datetime, timedelta
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass

from app.schemas.portfolio_analysis import (
    PortfolioHoldingInput,
    AllocationTarget,
    EnrichedHolding,
    RebalancingAction,
    CurrentMetrics,
    AnalysisSummary,
    PortfolioAnalysisResponse,
)
from app.services.fund_data_service import fund_data_service, CATEGORY_TO_ASSET_CLASS

logger = logging.getLogger(__name__)

# Tax constants for India (as of 2024)
LTCG_THRESHOLD_DAYS = 365  # Holding period for LTCG
LTCG_TAX_RATE = 0.10  # 10% above 1 lakh exemption
STCG_TAX_RATE = 0.15  # 15% flat
LTCG_EXEMPTION = 100000  # 1 lakh exemption per year

# Rebalancing thresholds
HIGH_PRIORITY_GAP = 0.15  # >15% off target = HIGH priority
MEDIUM_PRIORITY_GAP = 0.05  # 5-15% off target = MEDIUM priority
CONCENTRATION_THRESHOLD = 0.40  # Single fund >40% = HIGH priority
CATEGORY_CONCENTRATION_THRESHOLD = 0.35  # Category >35% = MEDIUM priority


@dataclass
class FundRecommendation:
    """Recommended fund for ADD_NEW actions."""
    scheme_code: int
    scheme_name: str
    category: str
    asset_class: str
    score: float


class PortfolioAnalysisService:
    """
    Analyzes current portfolio against target allocation.
    Generates rebalancing roadmap with tax awareness.
    """

    def __init__(self):
        self.model_version = "portfolio-analyzer-v1"

    def get_model_version(self) -> str:
        return self.model_version

    async def analyze(
        self,
        holdings: List[PortfolioHoldingInput],
        target_allocation: AllocationTarget,
        profile: dict,
    ) -> PortfolioAnalysisResponse:
        """
        Main analysis method.

        1. Enrich holdings with current NAV and metrics
        2. Calculate current allocation by asset class
        3. Compare against target allocation
        4. Generate rebalancing actions
        5. Add tax flags

        Args:
            holdings: List of current portfolio holdings
            target_allocation: Target allocation from persona classification
            profile: User profile data

        Returns:
            PortfolioAnalysisResponse with analysis and rebalancing actions
        """
        start_time = time.time()

        # Step 1: Enrich holdings with current data
        enriched_holdings = await self._enrich_holdings(holdings)

        # Step 2: Calculate current allocation
        total_value = sum(h.current_value for h in enriched_holdings)
        current_allocation = self._calculate_current_allocation(enriched_holdings, total_value)

        # Step 3: Calculate gaps
        allocation_gaps = self._calculate_gaps(current_allocation, target_allocation)

        # Step 4: Calculate current metrics
        current_metrics = self._calculate_metrics(enriched_holdings, total_value)

        # Step 5: Generate rebalancing actions
        rebalancing_actions = await self._generate_rebalancing_actions(
            enriched_holdings,
            allocation_gaps,
            target_allocation,
            total_value,
            profile,
        )

        # Step 6: Generate summary
        summary = self._generate_summary(
            current_allocation,
            target_allocation,
            allocation_gaps,
            rebalancing_actions,
            total_value,
        )

        latency_ms = (time.time() - start_time) * 1000

        return PortfolioAnalysisResponse(
            current_allocation=current_allocation,
            target_allocation=target_allocation,
            allocation_gaps=allocation_gaps,
            current_metrics=current_metrics,
            holdings=enriched_holdings,
            rebalancing_actions=rebalancing_actions,
            summary=summary,
            model_version=self.model_version,
            latency_ms=latency_ms,
        )

    async def _enrich_holdings(
        self, holdings: List[PortfolioHoldingInput]
    ) -> List[EnrichedHolding]:
        """Fetch current NAV, category, metrics for each holding."""
        enriched = []

        # Ensure fund data is available
        await fund_data_service.initialize()

        for holding in holdings:
            fund = await fund_data_service.get_fund(holding.scheme_code)

            if fund:
                # Calculate current value
                if holding.amount is not None:
                    current_value = holding.amount
                    units = holding.amount / fund.nav if fund.nav > 0 else None
                elif holding.units is not None and fund.nav > 0:
                    current_value = holding.units * fund.nav
                    units = holding.units
                else:
                    current_value = 0
                    units = None

                # Calculate tax status
                holding_period_days = None
                tax_status = None
                unrealized_gain = None

                if holding.purchase_date:
                    holding_period_days = (date.today() - holding.purchase_date).days
                    tax_status = "LTCG" if holding_period_days > LTCG_THRESHOLD_DAYS else "STCG"

                if holding.purchase_amount is not None and current_value > 0:
                    unrealized_gain = current_value - holding.purchase_amount

                enriched.append(
                    EnrichedHolding(
                        scheme_code=holding.scheme_code,
                        scheme_name=fund.scheme_name,
                        category=fund.category,
                        asset_class=fund.asset_class or CATEGORY_TO_ASSET_CLASS.get(fund.category, "equity"),
                        current_value=current_value,
                        weight=0,  # Will be calculated after total
                        units=units,
                        nav=fund.nav,
                        return_1y=fund.return_1y,
                        return_3y=fund.return_3y,
                        volatility=fund.volatility,
                        sharpe_ratio=fund.sharpe_ratio,
                        holding_period_days=holding_period_days,
                        tax_status=tax_status,
                        purchase_amount=holding.purchase_amount,
                        unrealized_gain=unrealized_gain,
                    )
                )
            else:
                # Fund not found in database - use provided data
                current_value = holding.amount or 0
                logger.warning(f"Fund {holding.scheme_code} not found in database")

                enriched.append(
                    EnrichedHolding(
                        scheme_code=holding.scheme_code,
                        scheme_name=holding.scheme_name or f"Unknown Fund ({holding.scheme_code})",
                        category="Unknown",
                        asset_class="equity",  # Default to equity
                        current_value=current_value,
                        weight=0,
                    )
                )

        # Calculate weights
        total_value = sum(h.current_value for h in enriched)
        if total_value > 0:
            for h in enriched:
                h.weight = h.current_value / total_value

        return enriched

    def _calculate_current_allocation(
        self, holdings: List[EnrichedHolding], total_value: float
    ) -> AllocationTarget:
        """Sum holdings by asset class."""
        allocation = {
            "equity": 0.0,
            "debt": 0.0,
            "hybrid": 0.0,
            "gold": 0.0,
            "international": 0.0,
            "liquid": 0.0,
        }

        if total_value <= 0:
            return AllocationTarget(**allocation)

        for holding in holdings:
            asset_class = holding.asset_class.lower()
            if asset_class in allocation:
                allocation[asset_class] += holding.current_value / total_value

        return AllocationTarget(**allocation)

    def _calculate_gaps(
        self, current: AllocationTarget, target: AllocationTarget
    ) -> Dict[str, float]:
        """Compute over/underweight positions."""
        return {
            "equity": current.equity - target.equity,
            "debt": current.debt - target.debt,
            "hybrid": current.hybrid - target.hybrid,
            "gold": current.gold - target.gold,
            "international": current.international - target.international,
            "liquid": current.liquid - target.liquid,
        }

    def _calculate_metrics(
        self, holdings: List[EnrichedHolding], total_value: float
    ) -> CurrentMetrics:
        """Calculate weighted portfolio metrics."""
        category_breakdown: Dict[str, Dict] = {}

        weighted_return_1y = 0.0
        weighted_return_3y = 0.0
        weighted_volatility = 0.0
        weighted_sharpe = 0.0
        count_with_returns = 0

        for holding in holdings:
            # Category breakdown
            if holding.category not in category_breakdown:
                category_breakdown[holding.category] = {
                    "allocation": 0.0,
                    "count": 0,
                    "value": 0.0,
                }
            category_breakdown[holding.category]["allocation"] += holding.weight
            category_breakdown[holding.category]["count"] += 1
            category_breakdown[holding.category]["value"] += holding.current_value

            # Weighted metrics
            if holding.return_1y is not None:
                weighted_return_1y += holding.return_1y * holding.weight
            if holding.return_3y is not None:
                weighted_return_3y += holding.return_3y * holding.weight
            if holding.volatility is not None:
                weighted_volatility += holding.volatility * holding.weight
            if holding.sharpe_ratio is not None:
                weighted_sharpe += holding.sharpe_ratio * holding.weight
            if holding.return_1y is not None or holding.return_3y is not None:
                count_with_returns += 1

        return CurrentMetrics(
            total_value=total_value,
            total_holdings=len(holdings),
            weighted_return_1y=round(weighted_return_1y, 2) if count_with_returns > 0 else None,
            weighted_return_3y=round(weighted_return_3y, 2) if count_with_returns > 0 else None,
            weighted_volatility=round(weighted_volatility, 2) if count_with_returns > 0 else None,
            weighted_sharpe=round(weighted_sharpe, 2) if count_with_returns > 0 else None,
            category_breakdown=category_breakdown,
        )

    async def _generate_rebalancing_actions(
        self,
        holdings: List[EnrichedHolding],
        gaps: Dict[str, float],
        target: AllocationTarget,
        total_value: float,
        profile: dict,
    ) -> List[RebalancingAction]:
        """
        Generate specific fund-level actions.

        Strategy:
        1. Identify overweight asset classes -> SELL actions
        2. Identify underweight asset classes -> BUY or ADD_NEW actions
        3. Prioritize tax-efficient selling (LTCG > STCG, losses first)
        4. Suggest new funds for unfilled gaps
        """
        actions: List[RebalancingAction] = []

        # Group holdings by asset class
        holdings_by_asset: Dict[str, List[EnrichedHolding]] = {}
        for h in holdings:
            asset_class = h.asset_class.lower()
            if asset_class not in holdings_by_asset:
                holdings_by_asset[asset_class] = []
            holdings_by_asset[asset_class].append(h)

        # Track proceeds from selling for buying
        proceeds = 0.0

        # Step 1: Generate SELL actions for overweight asset classes
        overweight_classes = [(ac, gap) for ac, gap in gaps.items() if gap > 0.01]
        overweight_classes.sort(key=lambda x: -x[1])  # Sort by largest overweight first

        for asset_class, gap in overweight_classes:
            asset_holdings = holdings_by_asset.get(asset_class, [])
            if not asset_holdings:
                continue

            # Sort by tax efficiency: losses first, then LTCG, then STCG
            def sell_priority(h: EnrichedHolding) -> Tuple:
                is_loss = (h.unrealized_gain or 0) < 0
                is_ltcg = h.tax_status == "LTCG"
                return (not is_loss, not is_ltcg, -(h.current_value or 0))

            asset_holdings.sort(key=sell_priority)

            # Calculate how much to sell from this asset class
            target_value = getattr(target, asset_class) * total_value
            current_value = sum(h.current_value for h in asset_holdings)
            amount_to_sell = current_value - target_value

            if amount_to_sell <= 0:
                continue

            # Generate SELL actions
            remaining_to_sell = amount_to_sell
            for holding in asset_holdings:
                if remaining_to_sell <= 0:
                    break

                sell_amount = min(holding.current_value, remaining_to_sell)
                new_value = holding.current_value - sell_amount
                new_weight = new_value / total_value if total_value > 0 else 0

                # Determine priority
                priority = self._determine_priority(gap, holding.weight)

                # Calculate tax implications
                tax_note = self._generate_tax_note(holding, sell_amount)
                estimated_gain = None
                if holding.purchase_amount is not None:
                    gain_ratio = sell_amount / holding.current_value if holding.current_value > 0 else 0
                    estimated_gain = (holding.unrealized_gain or 0) * gain_ratio

                # Check if this is a recent purchase - suggest HOLD instead
                if holding.holding_period_days and holding.holding_period_days < LTCG_THRESHOLD_DAYS:
                    days_to_ltcg = LTCG_THRESHOLD_DAYS - holding.holding_period_days
                    if days_to_ltcg < 90 and sell_amount < amount_to_sell * 0.5:
                        # Recent purchase, suggest holding if it's not majority of rebalancing need
                        actions.append(
                            RebalancingAction(
                                action="HOLD",
                                priority="LOW",
                                scheme_code=holding.scheme_code,
                                scheme_name=holding.scheme_name,
                                category=holding.category,
                                asset_class=holding.asset_class,
                                current_value=holding.current_value,
                                current_weight=holding.weight,
                                target_value=new_value,
                                target_weight=new_weight,
                                transaction_amount=-sell_amount,
                                tax_status=holding.tax_status,
                                holding_period_days=holding.holding_period_days,
                                estimated_gain=estimated_gain,
                                tax_note=f"STCG: Consider holding till {(date.today().replace(day=1) + timedelta(days=days_to_ltcg + 30)).strftime('%b %Y')} for LTCG",
                                reason=f"Recently purchased ({holding.holding_period_days} days); defer sale if possible for LTCG treatment",
                            )
                        )
                        continue

                actions.append(
                    RebalancingAction(
                        action="SELL",
                        priority=priority,
                        scheme_code=holding.scheme_code,
                        scheme_name=holding.scheme_name,
                        category=holding.category,
                        asset_class=holding.asset_class,
                        current_value=holding.current_value,
                        current_weight=holding.weight,
                        target_value=new_value,
                        target_weight=new_weight,
                        transaction_amount=-sell_amount,
                        transaction_units=sell_amount / holding.nav if holding.nav and holding.nav > 0 else None,
                        tax_status=holding.tax_status,
                        holding_period_days=holding.holding_period_days,
                        estimated_gain=estimated_gain,
                        tax_note=tax_note,
                        reason=f"Reduce {asset_class} overweight ({gap*100:.1f}%); {holding.tax_status or 'Unknown'} eligible",
                    )
                )

                remaining_to_sell -= sell_amount
                proceeds += sell_amount

        # Step 2: Generate BUY/ADD_NEW actions for underweight asset classes
        underweight_classes = [(ac, gap) for ac, gap in gaps.items() if gap < -0.01]
        underweight_classes.sort(key=lambda x: x[1])  # Sort by most underweight first

        for asset_class, gap in underweight_classes:
            target_value = getattr(target, asset_class) * total_value
            current_value = sum(h.current_value for h in holdings_by_asset.get(asset_class, []))
            amount_to_buy = target_value - current_value

            if amount_to_buy <= 0:
                continue

            priority = self._determine_priority(abs(gap), 0)

            # Check if we have existing funds in this asset class to top up
            existing_funds = holdings_by_asset.get(asset_class, [])

            if existing_funds:
                # BUY more of existing funds
                buy_per_fund = amount_to_buy / len(existing_funds)
                for holding in existing_funds:
                    new_value = holding.current_value + buy_per_fund
                    new_weight = new_value / total_value if total_value > 0 else 0

                    actions.append(
                        RebalancingAction(
                            action="BUY",
                            priority=priority,
                            scheme_code=holding.scheme_code,
                            scheme_name=holding.scheme_name,
                            category=holding.category,
                            asset_class=holding.asset_class,
                            current_value=holding.current_value,
                            current_weight=holding.weight,
                            target_value=new_value,
                            target_weight=new_weight,
                            transaction_amount=buy_per_fund,
                            transaction_units=buy_per_fund / holding.nav if holding.nav and holding.nav > 0 else None,
                            reason=f"Increase {asset_class} allocation (gap: {gap*100:.1f}%)",
                        )
                    )
            else:
                # ADD_NEW - need to recommend new funds
                recommendations = await self._get_fund_recommendations(asset_class, target_value)

                if recommendations:
                    # Distribute amount across recommended funds
                    buy_per_fund = amount_to_buy / len(recommendations)
                    for rec in recommendations:
                        new_weight = buy_per_fund / total_value if total_value > 0 else 0

                        actions.append(
                            RebalancingAction(
                                action="ADD_NEW",
                                priority=priority,
                                scheme_code=rec.scheme_code,
                                scheme_name=rec.scheme_name,
                                category=rec.category,
                                asset_class=asset_class,
                                current_value=0,
                                current_weight=0,
                                target_value=buy_per_fund,
                                target_weight=new_weight,
                                transaction_amount=buy_per_fund,
                                reason=f"Add {asset_class} allocation (currently {current_value/total_value*100:.1f}% vs target {getattr(target, asset_class)*100:.1f}%)",
                            )
                        )
                else:
                    # No specific recommendation, generic ADD_NEW action
                    actions.append(
                        RebalancingAction(
                            action="ADD_NEW",
                            priority=priority,
                            scheme_code=0,
                            scheme_name=f"Add {asset_class.capitalize()} Fund",
                            category=asset_class.capitalize(),
                            asset_class=asset_class,
                            current_value=0,
                            current_weight=0,
                            target_value=amount_to_buy,
                            target_weight=amount_to_buy / total_value if total_value > 0 else 0,
                            transaction_amount=amount_to_buy,
                            reason=f"Add {asset_class} allocation (currently 0% vs target {getattr(target, asset_class)*100:.1f}%)",
                        )
                    )

        # Sort actions by priority
        priority_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
        actions.sort(key=lambda a: (priority_order.get(a.priority, 3), -abs(a.transaction_amount)))

        return actions

    def _determine_priority(self, gap: float, weight: float) -> str:
        """Determine action priority based on gap and concentration."""
        if gap > HIGH_PRIORITY_GAP or weight > CONCENTRATION_THRESHOLD:
            return "HIGH"
        elif gap > MEDIUM_PRIORITY_GAP or weight > CATEGORY_CONCENTRATION_THRESHOLD:
            return "MEDIUM"
        return "LOW"

    def _generate_tax_note(self, holding: EnrichedHolding, sell_amount: float) -> Optional[str]:
        """Generate tax note for SELL action."""
        if not holding.tax_status:
            return None

        if holding.unrealized_gain and holding.unrealized_gain < 0:
            return "Tax-loss harvesting opportunity"

        if holding.tax_status == "LTCG":
            return f"LTCG: 10% tax on gains above INR 1 lakh"
        else:
            return f"STCG: 15% tax on gains"

    async def _get_fund_recommendations(
        self, asset_class: str, target_amount: float
    ) -> List[FundRecommendation]:
        """Get fund recommendations for a specific asset class."""
        recommendations = []

        # Get all funds and filter by asset class
        all_funds = await fund_data_service.get_all_funds()

        matching_funds = [
            f for f in all_funds
            if (f.asset_class or CATEGORY_TO_ASSET_CLASS.get(f.category, "equity")).lower() == asset_class.lower()
        ]

        if not matching_funds:
            return recommendations

        # Score and sort funds
        def score_fund(fund) -> float:
            score = 0.0
            # Prefer higher Sharpe ratio
            if fund.sharpe_ratio and fund.sharpe_ratio > 0:
                score += min(fund.sharpe_ratio / 2, 1) * 0.3
            # Prefer 3Y returns
            if fund.return_3y and fund.return_3y > 0:
                score += min(fund.return_3y / 30, 1) * 0.3
            # Prefer lower expense ratio
            if fund.expense_ratio and fund.expense_ratio > 0:
                score += max(0, 1 - fund.expense_ratio / 2) * 0.2
            # Prefer lower volatility
            if fund.volatility and fund.volatility > 0:
                score += max(0, 1 - fund.volatility / 30) * 0.2
            return score

        scored_funds = [(f, score_fund(f)) for f in matching_funds]
        scored_funds.sort(key=lambda x: -x[1])

        # Return top 2 recommendations
        for fund, score in scored_funds[:2]:
            recommendations.append(
                FundRecommendation(
                    scheme_code=fund.scheme_code,
                    scheme_name=fund.scheme_name,
                    category=fund.category,
                    asset_class=asset_class,
                    score=score,
                )
            )

        return recommendations

    def _generate_summary(
        self,
        current: AllocationTarget,
        target: AllocationTarget,
        gaps: Dict[str, float],
        actions: List[RebalancingAction],
        total_value: float,
    ) -> AnalysisSummary:
        """Generate analysis summary."""
        # Calculate alignment score
        total_gap = sum(abs(g) for g in gaps.values())
        alignment_score = max(0, 1 - total_gap / 2)  # Normalize to 0-1

        # Identify primary issues
        issues = []
        for asset_class, gap in gaps.items():
            if abs(gap) > 0.05:  # More than 5% off
                current_pct = getattr(current, asset_class) * 100
                target_pct = getattr(target, asset_class) * 100
                if gap > 0:
                    issues.append(f"{current_pct:.0f}% {asset_class} (target: {target_pct:.0f}%)")
                else:
                    issues.append(f"No {asset_class} allocation" if current_pct == 0 else f"Only {current_pct:.0f}% {asset_class} (target: {target_pct:.0f}%)")

        # Calculate transaction totals
        total_sell = sum(-a.transaction_amount for a in actions if a.action == "SELL")
        total_buy = sum(a.transaction_amount for a in actions if a.action in ["BUY", "ADD_NEW"])

        # Calculate tax impact
        total_ltcg_gain = sum(
            a.estimated_gain or 0
            for a in actions
            if a.action == "SELL" and a.tax_status == "LTCG" and (a.estimated_gain or 0) > 0
        )
        total_stcg_gain = sum(
            a.estimated_gain or 0
            for a in actions
            if a.action == "SELL" and a.tax_status == "STCG" and (a.estimated_gain or 0) > 0
        )

        tax_notes = []
        if total_ltcg_gain > LTCG_EXEMPTION:
            ltcg_tax = (total_ltcg_gain - LTCG_EXEMPTION) * LTCG_TAX_RATE
            tax_notes.append(f"Estimated INR {ltcg_tax:,.0f} LTCG tax (gains: INR {total_ltcg_gain:,.0f} above INR 1L exemption)")
        if total_stcg_gain > 0:
            stcg_tax = total_stcg_gain * STCG_TAX_RATE
            tax_notes.append(f"Estimated INR {stcg_tax:,.0f} STCG tax (gains: INR {total_stcg_gain:,.0f})")

        tax_summary = "; ".join(tax_notes) if tax_notes else "No significant tax impact expected"

        return AnalysisSummary(
            is_aligned=alignment_score >= 0.85,
            alignment_score=round(alignment_score, 2),
            primary_issues=issues[:5],  # Top 5 issues
            total_sell_amount=total_sell,
            total_buy_amount=total_buy,
            net_transaction=total_buy - total_sell,
            tax_impact_summary=tax_summary,
        )


# Singleton instance
portfolio_analysis_service = PortfolioAnalysisService()
