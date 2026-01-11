import { MutualFund } from '@/utils/constants';

interface Props {
  nest: MutualFund;
  activeRange: '1M' | '1Y' | '3Y' | '5Y';
  onRangeChange: (range: Props['activeRange']) => void;
}

const NestPerformanceChart = ({ nest, activeRange, onRangeChange }: Props) => {
  const values = nest.performance.map((p) => p.value);
  const max = Math.max(...values);
  const min = Math.min(...values);
  const points = nest.performance
    .map((p, i) => {
      const x = (i / (nest.performance.length - 1)) * 100;
      const y = 100 - ((p.value - min) / (max - min || 1)) * 100;
      return `${x},${y}`;
    })
    .join(' ');

  const ranges: Props['activeRange'][] = ['1M', '1Y', '3Y', '5Y'];

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-sparrow-navy/70">Fund performance</p>
          <h3 className="text-lg font-semibold text-sparrow-navy">Growth of ₹100</h3>
        </div>
        <div className="flex items-center gap-2">
          {ranges.map((range) => (
            <button
              key={range}
              onClick={() => onRangeChange(range)}
              className={`px-3 py-1.5 text-sm rounded-lg border ${
                activeRange === range
                  ? 'bg-sparrow-blue text-white border-sparrow-blue'
                  : 'border-sparrow-gray text-sparrow-navy'
              }`}
            >
              {range}
            </button>
          ))}
        </div>
      </div>
      <div className="mt-4">
        <svg viewBox="0 0 100 100" className="w-full h-40">
          <defs>
            <linearGradient id="nestPerf" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#3A7BFF" stopOpacity="0.35" />
              <stop offset="100%" stopColor="#0044FF" stopOpacity="0.08" />
            </linearGradient>
          </defs>
          <polyline
            fill="url(#nestPerf)"
            stroke="#006BFF"
            strokeWidth="1.4"
            points={`0,100 ${points} 100,100`}
          />
        </svg>
      </div>
    </div>
  );
};

export default NestPerformanceChart;
