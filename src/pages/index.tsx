import Link from 'next/link';

const Home = () => {
  return (
    <div className="page-shell">
      <main className="max-w-6xl mx-auto px-6 py-16">
        <div className="glass-card rounded-[32px] p-10 md:p-14 reveal">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-8">
            <div className="max-w-2xl">
              <p className="text-xs uppercase text-sparrow-navy/60">Sparrow Invest</p>
              <h1 className="text-3xl md:text-5xl font-semibold text-sparrow-navy mt-3">
                Intelligent mutual fund portfolios, crafted for Indian investors
              </h1>
              <p className="text-sm md:text-base text-sparrow-navy/70 mt-4">
                A modern, AI-first platform that builds investor personas, aligns portfolios to goals, and keeps recommendations transparent.
              </p>
            </div>
            <div className="flex flex-col gap-3">
              <span className="chip w-fit">iOS 26 inspired interface</span>
              <span className="chip w-fit">Persona-driven allocation</span>
              <span className="chip w-fit">Tax-aware fund mix</span>
            </div>
          </div>

          <div className="mt-10 grid md:grid-cols-2 gap-5">
            <Link href="/dashboard?mode=admin" className="surface-card p-6 reveal">
              <p className="text-xs uppercase text-sparrow-navy/60">Admin access</p>
              <h2 className="text-xl font-semibold text-sparrow-navy mt-2">Recommendation Studio</h2>
              <p className="text-sm text-sparrow-navy/70 mt-2">
                Review personas, risk guardrails, fund scoring, and investor mappings.
              </p>
              <div className="mt-4">
                <button className="btn-primary text-sm">Enter admin</button>
              </div>
            </Link>

            <Link href="/dashboard?mode=user" className="surface-card p-6 reveal">
              <p className="text-xs uppercase text-sparrow-navy/60">User access</p>
              <h2 className="text-xl font-semibold text-sparrow-navy mt-2">Investor Journey</h2>
              <p className="text-sm text-sparrow-navy/70 mt-2">
                Create a profile, discover your persona, and track a goal-based portfolio.
              </p>
              <div className="mt-4">
                <button className="btn-primary text-sm">Enter user</button>
              </div>
            </Link>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Home;
