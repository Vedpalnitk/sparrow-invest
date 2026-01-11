interface Signal {
  title: string;
  detail: string;
  impact: string;
}

interface MoversListProps {
  data: Signal[];
}

const MoversList = ({ data }: MoversListProps) => {
  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-sparrow-navy">AI signals</h3>
        <button className="text-sm text-sparrow-blue">View playbook</button>
      </div>
      <div className="space-y-4">
        {data.map((signal) => (
          <div key={signal.title} className="rounded-xl border border-sparrow-gray/60 p-3">
            <p className="text-sm font-semibold text-sparrow-navy">{signal.title}</p>
            <p className="text-xs text-sparrow-navy/70 mt-1">{signal.detail}</p>
            <p className="text-xs text-sparrow-blue mt-2">{signal.impact}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default MoversList;
