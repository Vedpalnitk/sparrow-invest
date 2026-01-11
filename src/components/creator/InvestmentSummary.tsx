import { formatCurrency } from '@/utils/formatters';

const InvestmentSummary = () => {
  const minInvestment = 24500;
  const estCagr = 15.2;

  return (
    <div className="card p-6 bg-gradient-to-br from-sparrow-gradientStart/10 to-sparrow-gradientEnd/10">
      <p className="text-sm text-sparrow-navy/70">Live minimum amount</p>
      <p className="text-2xl font-semibold text-sparrow-navy">{formatCurrency(minInvestment)}</p>
      <p className="text-sm text-sparrow-success font-semibold mt-1">Estimated CAGR {estCagr}%</p>
      <div className="mt-4 flex items-center gap-3">
        <button className="btn-primary">Invest now</button>
        <button className="px-4 py-2 rounded-xl border border-sparrow-gray font-semibold text-sparrow-navy">
          Save nest
        </button>
      </div>
    </div>
  );
};

export default InvestmentSummary;
