import { MutualFundHolding } from '@/utils/constants';
import { formatWeight } from '@/utils/formatters';

interface Props {
  holdings: MutualFundHolding[];
}

const NestHoldingsTable = ({ holdings }: Props) => {
  return (
    <div className="card p-6 overflow-x-auto">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-semibold text-sparrow-navy">Top holdings</h3>
        <button className="text-sm text-sparrow-blue">Download factsheet</button>
      </div>
      <table className="min-w-full text-sm">
        <thead className="text-left text-sparrow-navy/60">
          <tr>
            <th className="py-2">Holding</th>
            <th className="py-2">Sector</th>
            <th className="py-2">Allocation</th>
          </tr>
        </thead>
        <tbody>
          {holdings.map((holding) => (
            <tr key={holding.name} className="border-t border-sparrow-gray/50">
              <td className="py-3">
                <p className="font-semibold text-sparrow-navy">{holding.name}</p>
              </td>
              <td className="py-3 text-sparrow-navy/70">{holding.sector}</td>
              <td className="py-3 font-semibold text-sparrow-navy">{formatWeight(holding.allocation)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default NestHoldingsTable;
