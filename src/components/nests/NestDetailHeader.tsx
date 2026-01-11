import { formatCurrency, formatPercent } from '@/utils/formatters';
import { MutualFund } from '@/utils/constants';

interface NestDetailHeaderProps {
  nest: MutualFund;
}

const NestDetailHeader = ({ nest }: NestDetailHeaderProps) => {
  return (
    <div className="card p-6 bg-gradient-to-br from-white to-sparrow-grayLight/70">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <p className="text-xs uppercase text-sparrow-navy/60">{nest.category} · {nest.subCategory}</p>
          <h1 className="text-2xl font-semibold text-sparrow-navy">{nest.name}</h1>
          <p className="text-sm text-sparrow-navy/70 mt-1">{nest.fundHouse} · Benchmark {nest.benchmark}</p>
          <div className="flex items-center gap-3 mt-2 text-sm flex-wrap">
            <span className="badge bg-sparrow-success/15 text-sparrow-success">{formatPercent(nest.returns1y)} 1Y</span>
            <span className="badge bg-sparrow-success/15 text-sparrow-success">{formatPercent(nest.returns3y)} 3Y</span>
            <span className="badge bg-sparrow-success/15 text-sparrow-success">{formatPercent(nest.returns5y)} 5Y</span>
            <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">{nest.risk} risk</span>
          </div>
        </div>
        <div className="text-right">
          <p className="text-xs text-sparrow-navy/60">Minimum SIP</p>
          <p className="text-xl font-semibold text-sparrow-navy">{formatCurrency(nest.minSip)}</p>
          <div className="mt-3 flex items-center justify-end gap-2">
            <button className="px-4 py-2 rounded-xl border border-sparrow-gray">Add to watchlist</button>
            <button className="btn-primary">Start SIP</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NestDetailHeader;
