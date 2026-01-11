import { useMemo } from 'react';
import { useRouter } from 'next/router';
import Navbar from '@/components/layout/Navbar';
import Footer from '@/components/layout/Footer';
import PageHeader from '@/components/layout/PageHeader';
import PortfolioCard from '@/components/dashboard/PortfolioCard';
import AccountSummary from '@/components/dashboard/AccountSummary';
import MoversList from '@/components/dashboard/MoversList';
import HoldingsTable from '@/components/dashboard/HoldingsTable';
import Watchlist from '@/components/dashboard/Watchlist';
import {
  aiSignals,
  engineModules,
  fundWatchlist,
  investorProfiles,
  personaProfile,
  personaProfiles,
  personaRules,
  portfolioProjection,
  portfolioSummary,
  profileHighlights,
  recommendedAllocation,
  recommendedFunds
} from '@/utils/constants';

const Dashboard = () => {
  const router = useRouter();
  const mode = useMemo(() => {
    const rawMode = Array.isArray(router.query.mode) ? router.query.mode[0] : router.query.mode;
    return rawMode === 'admin' ? 'admin' : 'user';
  }, [router.query.mode]);
  const isAdmin = mode === 'admin';

  return (
    <div className="page-shell">
      <Navbar mode={mode} />
      <main className="max-w-7xl mx-auto px-6 py-10">
        <PageHeader
          title={isAdmin ? 'Recommendation Studio' : 'AI Portfolio Manager'}
          subtitle={
            isAdmin
              ? 'Monitor personas, guardrails, scoring layers, and portfolio drift.'
              : 'Institutional-grade investor profiling and goal-aligned mutual fund portfolios.'
          }
          actions={<button className="btn-primary">{isAdmin ? 'Run audit' : 'Review plan'}</button>}
        />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <PortfolioCard
              title={isAdmin ? 'Aggregate goal coverage' : 'Projected goal value'}
              value={portfolioSummary.projectedValue}
              changePct={portfolioSummary.expectedCagr}
              series={portfolioProjection}
              confidence={portfolioSummary.confidence}
              ctaLabel={isAdmin ? 'Export report' : 'Rebalance now'}
            />
            <AccountSummary metrics={profileHighlights} persona={personaProfile} />
            <div className="card p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-sparrow-navy">Recommended allocation mix</h3>
                <button className="text-sm text-sparrow-blue">Why this mix?</button>
              </div>
              <div className="space-y-3">
                {recommendedAllocation.map((bucket) => (
                  <div key={bucket.label} className="rounded-2xl border border-sparrow-gray/40 p-4 bg-white/70">
                    <div className="flex items-center justify-between text-sm font-semibold text-sparrow-navy">
                      <span>{bucket.label}</span>
                      <span>{bucket.value}%</span>
                    </div>
                    <div className="mt-3 h-2 rounded-full bg-sparrow-grayLight">
                      <div
                        className="h-2 rounded-full bg-gradient-to-r from-sparrow-gradientStart to-sparrow-gradientEnd"
                        style={{ width: `${bucket.value}%` }}
                      />
                    </div>
                    <p className="text-xs text-sparrow-navy/60 mt-2">{bucket.note}</p>
                  </div>
                ))}
              </div>
            </div>
            <HoldingsTable rows={recommendedFunds} />
          </div>
          <div className="space-y-6">
            {isAdmin && (
              <div className="card p-6">
                <h3 className="text-lg font-semibold text-sparrow-navy">Engine modules</h3>
                <p className="text-sm text-sparrow-navy/70 mt-1">
                  Real-time insight into model scoring, constraints, and compliance coverage.
                </p>
                <div className="mt-4 space-y-3">
                  {engineModules.map((module) => (
                    <div key={module.title} className="p-3 rounded-2xl bg-sparrow-grayLight/80">
                      <p className="text-sm font-semibold text-sparrow-navy">{module.title}</p>
                      <p className="text-xs text-sparrow-navy/70 mt-1">{module.detail}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
            {isAdmin && (
              <div className="card p-6">
                <h3 className="text-lg font-semibold text-sparrow-navy">Persona rules engine</h3>
                <p className="text-sm text-sparrow-navy/70 mt-1">
                  Signals derived from age, horizon, cash-flow resilience, and drawdown tolerance.
                </p>
                <div className="mt-4 space-y-3">
                  {personaRules.map((rule) => (
                    <div key={rule.label} className="p-3 rounded-2xl bg-sparrow-grayLight/80">
                      <p className="text-sm font-semibold text-sparrow-navy">{rule.label}</p>
                      <p className="text-xs text-sparrow-navy/70 mt-1">{rule.detail}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
            {isAdmin && (
              <div className="card p-6">
                <h3 className="text-lg font-semibold text-sparrow-navy">Persona library</h3>
                <p className="text-sm text-sparrow-navy/70 mt-1">Active personas and allocation biases.</p>
                <div className="mt-4 space-y-3">
                  {personaProfiles.map((persona) => (
                    <div key={persona.name} className="p-3 rounded-2xl border border-sparrow-gray/40 bg-white/70">
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-semibold text-sparrow-navy">{persona.name}</p>
                        <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">{persona.riskBand}</span>
                      </div>
                      <p className="text-xs text-sparrow-navy/70 mt-1">{persona.description}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
            {isAdmin && (
              <div className="card p-6">
                <h3 className="text-lg font-semibold text-sparrow-navy">Investor profiles</h3>
                <p className="text-sm text-sparrow-navy/70 mt-1">Profiles mapped to personas and status.</p>
                <div className="mt-4 space-y-3">
                  {investorProfiles.map((profile) => (
                    <div key={profile.id} className="p-3 rounded-2xl bg-sparrow-grayLight/80">
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-semibold text-sparrow-navy">{profile.name}</p>
                        <span className="badge bg-sparrow-blue/10 text-sparrow-blue">{profile.status}</span>
                      </div>
                      <p className="text-xs text-sparrow-navy/70 mt-1">
                        Persona {profile.persona} · {profile.horizonYears}Y horizon · SIP ₹{profile.monthlySip.toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            )}
            <MoversList data={aiSignals} />
            <Watchlist items={fundWatchlist} />
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Dashboard;
