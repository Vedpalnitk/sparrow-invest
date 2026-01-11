const Footer = () => {
  return (
    <footer className="mt-16 border-t border-sparrow-gray/60 bg-white/80 backdrop-blur">
      <div className="max-w-7xl mx-auto px-6 py-8 grid grid-cols-1 md:grid-cols-3 gap-6 text-sm text-sparrow-navy/70">
        <div>
          <p className="text-base font-semibold text-sparrow-navy brand-font">Sparrow Invest</p>
          <p className="mt-2">AI-driven investor profiling and goal-aligned mutual fund portfolios.</p>
        </div>
        <div>
          <p className="font-semibold text-sparrow-navy">Product</p>
          <ul className="mt-2 space-y-1">
            <li>Overview</li>
            <li>Fund Universe</li>
            <li>Investor Profile</li>
          </ul>
        </div>
        <div>
          <p className="font-semibold text-sparrow-navy">Support</p>
          <ul className="mt-2 space-y-1">
            <li>Help center</li>
            <li>Regulatory disclosures</li>
            <li>Contact advisor</li>
          </ul>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
