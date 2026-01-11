import { useState } from 'react';

const WeightingScheme = () => {
  const [scheme, setScheme] = useState<'equal' | 'custom'>('equal');

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-semibold text-sparrow-navy">Weighting scheme</h3>
        <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">Draft</span>
      </div>
      <div className="flex gap-3">
        {['equal', 'custom'].map((option) => (
          <button
            key={option}
            onClick={() => setScheme(option as 'equal' | 'custom')}
            className={`px-4 py-3 rounded-xl border text-sm font-semibold capitalize ${
              scheme === option
                ? 'border-sparrow-blue text-sparrow-blue bg-sparrow-blue/10'
                : 'border-sparrow-gray text-sparrow-navy'
            }`}
          >
            {option} weighted
          </button>
        ))}
      </div>
      <p className="text-sm text-sparrow-navy/70 mt-3">
        Equal weighted allocates evenly across holdings. Custom lets you tune exposure and risk.
      </p>
    </div>
  );
};

export default WeightingScheme;
