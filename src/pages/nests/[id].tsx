import { useMemo, useState } from 'react';
import { useRouter } from 'next/router';
import Navbar from '@/components/layout/Navbar';
import Footer from '@/components/layout/Footer';
import NestDetailHeader from '@/components/nests/NestDetailHeader';
import NestAboutSection from '@/components/nests/NestAboutSection';
import NestPerformanceChart from '@/components/nests/NestPerformanceChart';
import NestHoldingsTable from '@/components/nests/NestHoldingsTable';
import NestManagerSection from '@/components/nests/NestManagerSection';
import { mutualFundList } from '@/utils/constants';
import { formatCurrency } from '@/utils/formatters';

const NestDetailPage = () => {
  const router = useRouter();
  const { id } = router.query;
  const slug = Array.isArray(id) ? id[0] : id;
  const [range, setRange] = useState<'1M' | '1Y' | '3Y' | '5Y'>('1Y');

  const mode = useMemo(() => {
    const rawMode = Array.isArray(router.query.mode) ? router.query.mode[0] : router.query.mode;
    return rawMode === 'admin' ? 'admin' : 'user';
  }, [router.query.mode]);

  const fund = useMemo(() => mutualFundList.find((n) => n.id === slug), [slug]);

  if (!fund) {
    return (
      <div className="min-h-screen flex items-center justify-center text-sparrow-navy">
        Loading fund...
      </div>
    );
  }

  return (
    <div className="page-shell">
      <Navbar mode={mode} />
      <main className="max-w-7xl mx-auto px-6 py-10 space-y-6">
        <NestDetailHeader nest={fund} />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <NestPerformanceChart nest={fund} activeRange={range} onRangeChange={setRange} />
            <NestHoldingsTable holdings={fund.holdings} />
            <NestAboutSection about={fund.description} />
            <NestManagerSection
              name={fund.manager}
              description={`Managing since ${fund.inception}. Benchmarked to ${fund.benchmark}.`}
            />
          </div>
          <div className="space-y-4">
            <div className="card p-5">
              <p className="text-sm text-sparrow-navy/70">Fund facts</p>
              <div className="mt-3 space-y-3 text-sm">
                <div className="flex items-center justify-between">
                  <span className="text-sparrow-navy/60">AUM</span>
                  <span className="font-semibold text-sparrow-navy">₹{fund.aumCr.toLocaleString()} Cr</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sparrow-navy/60">Expense ratio</span>
                  <span className="font-semibold text-sparrow-navy">{fund.expenseRatio}%</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sparrow-navy/60">Minimum lump sum</span>
                  <span className="font-semibold text-sparrow-navy">{formatCurrency(fund.minLumpSum)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sparrow-navy/60">Exit load</span>
                  <span className="font-semibold text-sparrow-navy text-right max-w-[160px]">{fund.exitLoad}</span>
                </div>
              </div>
              <div className="mt-4 flex flex-col gap-2">
                <button className="btn-primary w-full text-center">{mode === 'admin' ? 'Add to model' : 'Start SIP'}</button>
                <button className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 font-semibold">Add to watchlist</button>
              </div>
            </div>
            <div className="card p-5">
              <p className="text-sm text-sparrow-navy/70">AI fit score</p>
              <p className="text-2xl font-semibold text-sparrow-navy mt-1">92 / 100</p>
              <p className="text-xs text-sparrow-navy/60 mt-1">Aligned with aggressive growth persona and 10+ year horizon.</p>
              <div className="mt-3">
                <button className="text-sm text-sparrow-blue">View rationale</button>
              </div>
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default NestDetailPage;
