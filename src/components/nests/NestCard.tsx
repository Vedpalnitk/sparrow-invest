import Link from 'next/link';
import { MutualFund } from '@/utils/constants';
import { formatCurrency, formatPercent } from '@/utils/formatters';

interface NestCardProps {
  nest: MutualFund;
}

const NestCard = ({ nest }: NestCardProps) => {
  return (
    <Link href={`/nests/${nest.id}`} className="card p-5 hover:shadow-md transition-shadow block">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs uppercase text-sparrow-navy/60">{nest.category} · {nest.subCategory}</p>
          <h3 className="text-lg font-semibold text-sparrow-navy mt-1">{nest.name}</h3>
          <p className="text-xs text-sparrow-navy/60 mt-1">{nest.fundHouse}</p>
        </div>
        <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">{nest.risk} risk</span>
      </div>
      <div className="grid grid-cols-2 gap-3 mt-4">
        <div>
          <p className="text-xs text-sparrow-navy/60">1Y return</p>
          <p className="text-lg font-semibold text-sparrow-success">{formatPercent(nest.returns1y)}</p>
        </div>
        <div>
          <p className="text-xs text-sparrow-navy/60">3Y return</p>
          <p className="text-lg font-semibold text-sparrow-success">{formatPercent(nest.returns3y)}</p>
        </div>
        <div>
          <p className="text-xs text-sparrow-navy/60">Min SIP</p>
          <p className="text-lg font-semibold text-sparrow-navy">{formatCurrency(nest.minSip)}</p>
        </div>
        <div className="flex items-center justify-end">
          <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">Expense {nest.expenseRatio}%</span>
        </div>
      </div>
      <div className="mt-4 flex items-center justify-between text-sm text-sparrow-navy/70">
        <p>Managed by <span className="font-semibold text-sparrow-navy">{nest.manager}</span></p>
        <button className="text-sparrow-blue font-semibold">View</button>
      </div>
    </Link>
  );
};

export default NestCard;
