import {
  investorProfile,
  investorProfiles,
  personaProfile,
  personaProfiles,
  personaRules
} from '@/utils/constants';

interface CreateNestPageProps {
  mode?: 'admin' | 'user';
}

const CreateNestPage = ({ mode = 'user' }: CreateNestPageProps) => {
  const isAdmin = mode === 'admin';

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2 space-y-6">
        <div className="card p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-xs uppercase text-sparrow-navy/60">Profile foundation</p>
              <h2 className="text-2xl font-semibold text-sparrow-navy">Investor details</h2>
              <p className="text-sm text-sparrow-navy/70 mt-1">Used to calibrate risk bands, liquidity buffers, and fund suitability.</p>
            </div>
            <button className="btn-ghost text-sm">Import KYC</button>
          </div>
          <div className="grid md:grid-cols-2 gap-4 text-sm">
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Full name</span>
              <input
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.fullName}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Profession</span>
              <input
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.profession}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Age</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.age}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">City</span>
              <input
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.city}
              />
            </label>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-xs uppercase text-sparrow-navy/60">Financial capacity</p>
              <h3 className="text-xl font-semibold text-sparrow-navy">Income & liquidity</h3>
            </div>
            <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">Tax bracket {investorProfile.taxBracket}</span>
          </div>
          <div className="grid md:grid-cols-2 gap-4 text-sm">
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Annual income</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.annualIncome}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Dependents</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.dependents}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Monthly SIP capacity</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.monthlySip}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Lump sum capacity</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.lumpSumCapacity}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Liquidity needs</span>
              <select
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.liquidityNeeds}
              >
                <option>Low</option>
                <option>Medium</option>
                <option>High</option>
              </select>
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Investment knowledge</span>
              <select
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.investmentKnowledge}
              >
                <option>Beginner</option>
                <option>Intermediate</option>
                <option>Advanced</option>
              </select>
            </label>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-xs uppercase text-sparrow-navy/60">Goals</p>
              <h3 className="text-xl font-semibold text-sparrow-navy">Goal-based planning</h3>
            </div>
            <button className="text-sm text-sparrow-blue font-semibold">Add secondary goal</button>
          </div>
          <div className="grid md:grid-cols-2 gap-4 text-sm">
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Primary goal</span>
              <input
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.goal.name}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Goal priority</span>
              <select
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.goal.priority}
              >
                <option>Core</option>
                <option>Aspirational</option>
              </select>
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Target amount (INR)</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.goal.targetAmount}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Target year</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.goal.targetYear}
              />
            </label>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-xs uppercase text-sparrow-navy/60">Risk discovery</p>
              <h3 className="text-xl font-semibold text-sparrow-navy">Risk attitude</h3>
            </div>
            <span className="badge bg-sparrow-blue/10 text-sparrow-blue">{investorProfile.riskTolerance} band</span>
          </div>
          <div className="grid md:grid-cols-2 gap-4 text-sm">
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Time horizon (years)</span>
              <input
                type="number"
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.timeHorizonYears}
              />
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Volatility comfort</span>
              <select
                className="w-full px-4 py-3 rounded-2xl border border-sparrow-gray/40 bg-white/80 focus:outline-none focus:ring-2 focus:ring-sparrow-blue"
                defaultValue={investorProfile.volatilityComfort}
              >
                <option>Low</option>
                <option>Medium</option>
                <option>High</option>
              </select>
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Equity preference</span>
              <input type="range" defaultValue={76} className="w-full accent-sparrow-blue" />
              <div className="flex justify-between text-xs text-sparrow-navy/60">
                <span>Capital preservation</span>
                <span>Growth focused</span>
              </div>
            </label>
            <label className="space-y-2">
              <span className="text-sparrow-navy/70">Liquidity buffer</span>
              <input type="range" defaultValue={25} className="w-full accent-sparrow-blue" />
              <div className="flex justify-between text-xs text-sparrow-navy/60">
                <span>Low buffer</span>
                <span>High buffer</span>
              </div>
            </label>
          </div>
        </div>
      </div>

      <div className="space-y-6">
        {isAdmin && (
          <div className="card p-6">
            <h3 className="text-lg font-semibold text-sparrow-navy">Investor profile directory</h3>
            <p className="text-sm text-sparrow-navy/70 mt-1">All profiles mapped to personas.</p>
            <div className="mt-4 space-y-3">
              {investorProfiles.map((profile) => (
                <div key={profile.id} className="p-3 rounded-2xl bg-sparrow-grayLight/80">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-semibold text-sparrow-navy">{profile.name}</p>
                    <span className="badge bg-sparrow-blue/10 text-sparrow-blue">{profile.status}</span>
                  </div>
                  <p className="text-xs text-sparrow-navy/70 mt-1">
                    Persona {profile.persona} · {profile.horizonYears}Y horizon · SIP ₹{profile.monthlySip.toLocaleString()}
                  </p>
                </div>
              ))}
            </div>
          </div>
        )}
        {isAdmin && (
          <div className="card p-6">
            <h3 className="text-lg font-semibold text-sparrow-navy">Persona library</h3>
            <p className="text-sm text-sparrow-navy/70 mt-1">Library of personas used by the engine.</p>
            <div className="mt-4 space-y-3">
              {personaProfiles.map((persona) => (
                <div key={persona.name} className="p-3 rounded-2xl border border-sparrow-gray/40 bg-white/70">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-semibold text-sparrow-navy">{persona.name}</p>
                    <span className="badge bg-sparrow-grayLight text-sparrow-navy/80">{persona.riskBand}</span>
                  </div>
                  <p className="text-xs text-sparrow-navy/70 mt-1">{persona.description}</p>
                </div>
              ))}
            </div>
          </div>
        )}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-sparrow-navy">AI persona preview</h3>
          <p className="text-sm text-sparrow-navy/70 mt-1">{personaProfile.description}</p>
          <div className="mt-4">
            <p className="text-xs text-sparrow-navy/60">Estimated persona</p>
            <p className="text-xl font-semibold text-sparrow-navy">{personaProfile.name}</p>
            <span className="badge bg-sparrow-success/15 text-sparrow-success mt-2 inline-flex">{personaProfile.riskBand}</span>
          </div>
          <div className="mt-4 space-y-2 text-sm">
            <div className="flex items-center justify-between">
              <span className="text-sparrow-navy/60">Equity bias</span>
              <span className="font-semibold text-sparrow-navy">{personaProfile.allocationBias.equity}%</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sparrow-navy/60">Debt bias</span>
              <span className="font-semibold text-sparrow-navy">{personaProfile.allocationBias.debt}%</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sparrow-navy/60">Hybrid/alt bias</span>
              <span className="font-semibold text-sparrow-navy">
                {personaProfile.allocationBias.hybrid + personaProfile.allocationBias.alternatives}%
              </span>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <h3 className="text-lg font-semibold text-sparrow-navy">Persona rules</h3>
          <p className="text-sm text-sparrow-navy/70 mt-1">Best-practice heuristics applied before AI optimization.</p>
          <div className="mt-4 space-y-3">
            {personaRules.map((rule) => (
              <div key={rule.label} className="p-3 rounded-2xl bg-sparrow-grayLight/80">
                <p className="text-sm font-semibold text-sparrow-navy">{rule.label}</p>
                <p className="text-xs text-sparrow-navy/70 mt-1">{rule.detail}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="card p-6">
          <h3 className="text-lg font-semibold text-sparrow-navy">Profile completeness</h3>
          <p className="text-sm text-sparrow-navy/70 mt-1">AI model coverage at 92% based on provided inputs.</p>
          <div className="mt-4">
            <div className="flex items-center justify-between text-sm font-semibold text-sparrow-navy">
              <span>Completion</span>
              <span>92%</span>
            </div>
            <div className="mt-2 h-2 rounded-full bg-sparrow-grayLight">
              <div className="h-2 rounded-full bg-gradient-to-r from-sparrow-gradientStart to-sparrow-gradientEnd" style={{ width: '92%' }} />
            </div>
            <p className="text-xs text-sparrow-navy/60 mt-2">
              Provide household net worth to unlock stress testing.
            </p>
            <div className="mt-4">
              <button className="btn-primary w-full">Run persona engine</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CreateNestPage;
