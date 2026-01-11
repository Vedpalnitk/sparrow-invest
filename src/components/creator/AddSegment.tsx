import { useState } from 'react';

const AddSegment = () => {
  const [segments, setSegments] = useState([
    { name: 'Bluechip core', weight: 40 },
    { name: 'Momentum tilt', weight: 30 },
    { name: 'Defensives', weight: 30 }
  ]);

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-semibold text-sparrow-navy">Segments</h3>
        <button className="btn-primary text-sm">Add segment</button>
      </div>
      <div className="space-y-3">
        {segments.map((segment) => (
          <div key={segment.name} className="flex items-center justify-between rounded-xl border border-sparrow-gray/70 p-3">
            <div>
              <p className="font-semibold text-sparrow-navy">{segment.name}</p>
              <p className="text-xs text-sparrow-navy/60">Custom mix</p>
            </div>
            <div className="flex items-center gap-2">
              <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">{segment.weight}%</span>
              <button className="text-xs text-sparrow-blue">Edit</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default AddSegment;
