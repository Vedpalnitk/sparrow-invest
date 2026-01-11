import { formatCurrency, formatPercent } from '@/utils/formatters';

interface FundRow {
  id: string;
  name: string;
  category: string;
  subCategory: string;
  risk: string;
  returns3y: number;
  returns5y: number;
  allocation: number;
  minSip: number;
}

interface HoldingsTableProps {
  rows: FundRow[];
}

const HoldingsTable = ({ rows }: HoldingsTableProps) => {
  return (
    <div className="card p-6 overflow-x-auto">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-sparrow-navy">Recommended funds</h3>
        <div className="flex items-center gap-2 text-xs text-sparrow-navy/70">
          <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">Direct plans</span>
          <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">Goal aligned</span>
        </div>
      </div>
      <table className="min-w-full text-sm">
        <thead className="text-left text-sparrow-navy/60">
          <tr>
            <th className="py-2">Fund</th>
            <th className="py-2">Category</th>
            <th className="py-2">3Y</th>
            <th className="py-2">5Y</th>
            <th className="py-2">Allocation</th>
            <th className="py-2">Min SIP</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id} className="border-t border-sparrow-gray/50">
              <td className="py-3">
                <div>
                  <p className="font-semibold text-sparrow-navy">{row.name}</p>
                  <p className="text-xs text-sparrow-navy/60">Risk: {row.risk}</p>
                </div>
              </td>
              <td className="py-3">
                <p className="text-sm text-sparrow-navy">{row.category}</p>
                <p className="text-xs text-sparrow-navy/60">{row.subCategory}</p>
              </td>
              <td className="py-3 text-sparrow-success font-semibold">{formatPercent(row.returns3y)}</td>
              <td className="py-3 text-sparrow-success font-semibold">{formatPercent(row.returns5y)}</td>
              <td className="py-3 font-semibold text-sparrow-navy">{formatPercent(row.allocation)}</td>
              <td className="py-3">{formatCurrency(row.minSip)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default HoldingsTable;
