import { formatCurrency, formatPercent } from '@/utils/formatters';

interface PortfolioCardProps {
  title: string;
  value: number;
  changePct: number;
  series: number[];
  confidence: string;
  ctaLabel: string;
}

const PortfolioCard = ({ title, value, changePct, series, confidence, ctaLabel }: PortfolioCardProps) => {
  const max = Math.max(...series);
  const min = Math.min(...series);
  const points = series
    .map((v, i) => {
      const x = (i / (series.length - 1)) * 100;
      const y = 100 - ((v - min) / (max - min || 1)) * 100;
      return `${x},${y}`;
    })
    .join(' ');

  return (
    <div className="card p-6 bg-gradient-to-br from-white to-sparrow-grayLight/80">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-sparrow-navy/70">{title}</p>
          <h2 className="text-3xl font-semibold text-sparrow-navy mt-1">{formatCurrency(value)}</h2>
          <div className="flex items-center gap-2 mt-2">
            <span className="badge bg-sparrow-success/15 text-sparrow-success">{formatPercent(changePct)}</span>
            <p className="text-xs text-sparrow-navy/60">Projected CAGR</p>
            <span className="badge bg-sparrow-grayLight text-sparrow-navy/70">Confidence: {confidence}</span>
          </div>
        </div>
        <button className="btn-primary text-sm">{ctaLabel}</button>
      </div>
      <div className="mt-6 bg-white rounded-xl p-4 border border-sparrow-gray/60">
        <svg viewBox="0 0 100 100" className="w-full h-32">
          <defs>
            <linearGradient id="portfolioLine" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#3A7BFF" stopOpacity="0.28" />
              <stop offset="100%" stopColor="#0044FF" stopOpacity="0.04" />
            </linearGradient>
          </defs>
          <polyline
            fill="url(#portfolioLine)"
            stroke="#3A7BFF"
            strokeWidth="1.5"
            points={`0,100 ${points} 100,100`}
          />
        </svg>
        <div className="mt-3 flex items-center justify-between text-xs text-sparrow-navy/60">
          <span>Goal year projection</span>
          <span>Auto-refreshes monthly</span>
        </div>
      </div>
    </div>
  );
};

export default PortfolioCard;
