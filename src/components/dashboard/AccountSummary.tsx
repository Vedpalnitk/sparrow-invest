interface ProfileMetric {
  label: string;
  value: string;
}

interface Persona {
  name: string;
  description: string;
  riskBand: string;
  behaviorSignals: string[];
}

interface AccountSummaryProps {
  metrics: ProfileMetric[];
  persona: Persona;
}

const AccountSummary = ({ metrics, persona }: AccountSummaryProps) => {
  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-sparrow-navy">Investor profile</h3>
        <button className="text-sm text-sparrow-blue font-medium">Edit profile</button>
      </div>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {metrics.map((metric) => (
          <div key={metric.label} className="p-3 rounded-xl bg-sparrow-grayLight">
            <p className="text-xs text-sparrow-navy/60">{metric.label}</p>
            <p className="text-sm font-semibold text-sparrow-navy mt-1">{metric.value}</p>
          </div>
        ))}
      </div>
      <div className="mt-6 border border-sparrow-gray/60 rounded-xl p-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs uppercase text-sparrow-navy/60">AI Persona</p>
            <h4 className="text-lg font-semibold text-sparrow-navy">{persona.name}</h4>
            <p className="text-sm text-sparrow-navy/70 mt-1">{persona.description}</p>
          </div>
          <span className="badge bg-sparrow-blue/10 text-sparrow-blue">{persona.riskBand}</span>
        </div>
        <div className="mt-4 flex flex-wrap gap-2">
          {persona.behaviorSignals.map((signal) => (
            <span key={signal} className="badge bg-sparrow-grayLight text-sparrow-navy/80">
              {signal}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};

export default AccountSummary;
