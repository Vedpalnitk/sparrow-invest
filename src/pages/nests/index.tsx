import { useMemo } from 'react';
import { useRouter } from 'next/router';
import Navbar from '@/components/layout/Navbar';
import Footer from '@/components/layout/Footer';
import PageHeader from '@/components/layout/PageHeader';
import NestCard from '@/components/nests/NestCard';
import { discoverBanners, mutualFundList, popularThemes } from '@/utils/constants';

const ExploreNests = () => {
  const router = useRouter();
  const mode = useMemo(() => {
    const rawMode = Array.isArray(router.query.mode) ? router.query.mode[0] : router.query.mode;
    return rawMode === 'admin' ? 'admin' : 'user';
  }, [router.query.mode]);

  const coreFunds = mutualFundList.slice(0, 3);
  const growthFunds = mutualFundList.slice(1, 4);
  const stabilityFunds = mutualFundList.slice(3, 6);

  return (
    <div className="page-shell">
      <Navbar mode={mode} />
      <main className="max-w-7xl mx-auto px-6 py-10 space-y-8">
        <PageHeader
          title={mode === 'admin' ? 'Fund universe control' : 'Mutual fund universe'}
          subtitle={
            mode === 'admin'
              ? 'Audit fund coverage, performance consistency, and fit score distribution.'
              : 'Curated Indian mutual funds with risk labels, performance history, and AI-fit signals.'
          }
          actions={<button className="btn-primary">{mode === 'admin' ? 'Export universe' : 'Run fit check'}</button>}
        />

        <div className="grid md:grid-cols-2 gap-4">
          {discoverBanners.map((banner) => (
            <div
              key={banner.title}
              className={`card p-5 ${
                banner.tone === 'primary'
                  ? 'bg-gradient-to-br from-sparrow-gradientStart/20 to-sparrow-gradientEnd/10'
                  : 'bg-white'
              }`}
            >
              <p className="text-sm text-sparrow-navy/70">{banner.title}</p>
              <h3 className="text-xl font-semibold text-sparrow-navy mt-1">{banner.description}</h3>
              <button className="btn-primary mt-3 text-sm w-fit">{banner.cta}</button>
            </div>
          ))}
        </div>

        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-sparrow-navy">Core portfolio picks</h3>
            <button className="text-sm text-sparrow-blue">See all core funds</button>
          </div>
          <div className="overflow-x-auto">
            <div className="flex gap-4 min-w-[720px]">
              {coreFunds.map((fund) => (
                <div key={fund.id} className="w-1/3 min-w-[220px] flex-1">
                  <NestCard nest={fund} />
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-sparrow-navy">Growth acceleration</h3>
            <button className="text-sm text-sparrow-blue">View growth funds</button>
          </div>
          <div className="grid md:grid-cols-3 gap-4">
            {growthFunds.map((fund) => (
              <NestCard key={fund.id} nest={fund} />
            ))}
          </div>
        </section>

        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-sparrow-navy">Stability & income</h3>
            <button className="text-sm text-sparrow-blue">Debt funds</button>
          </div>
          <div className="grid md:grid-cols-3 gap-4">
            {stabilityFunds.map((fund) => (
              <NestCard key={`${fund.id}-stable`} nest={fund} />
            ))}
          </div>
        </section>

        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-sparrow-navy">Popular categories</h3>
            <button className="text-sm text-sparrow-blue">Browse categories</button>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {popularThemes.map((theme) => (
              <div key={theme.name} className="card p-4 text-sm">
                <p className="text-sparrow-navy/60">Category</p>
                <p className="text-base font-semibold text-sparrow-navy">{theme.name}</p>
                <p className="text-xs text-sparrow-navy/60 mt-1">{theme.funds} funds</p>
              </div>
            ))}
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
};

export default ExploreNests;
