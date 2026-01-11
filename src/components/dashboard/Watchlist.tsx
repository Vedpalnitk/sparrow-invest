interface WatchItem {
  name: string;
  category: string;
  nav: number;
  change: number;
}

interface WatchlistProps {
  items: WatchItem[];
}

const Watchlist = ({ items }: WatchlistProps) => {
  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-sparrow-navy">Fund watchlist</h3>
        <button className="text-sm text-sparrow-blue">Manage</button>
      </div>
      <div className="space-y-3">
        {items.map((item) => (
          <div key={item.name} className="flex items-center justify-between">
            <div>
              <p className="text-sm font-semibold text-sparrow-navy">{item.name}</p>
              <p className="text-xs text-sparrow-navy/60">{item.category}</p>
            </div>
            <div className="text-right">
              <p className="text-sm font-semibold text-sparrow-navy">NAV ₹{item.nav.toFixed(1)}</p>
              <p className={`text-xs ${item.change >= 0 ? 'text-sparrow-success' : 'text-sparrow-error'}`}>
                {item.change >= 0 ? '+' : ''}
                {item.change}%
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Watchlist;
