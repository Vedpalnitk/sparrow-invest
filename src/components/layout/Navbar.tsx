import Link from 'next/link';
import { navLinks } from '@/utils/constants';

interface NavbarProps {
  mode?: 'admin' | 'user';
}

const Navbar = ({ mode = 'user' }: NavbarProps) => {
  const scopedLinks = mode === 'admin'
    ? [
        { label: 'Overview', href: '/dashboard?mode=admin' },
        { label: 'Personas', href: '/nests?mode=admin' },
        { label: 'Profiles', href: '/nests/create?mode=admin' }
      ]
    : navLinks;

  return (
    <header className="sticky top-0 z-20 backdrop-blur bg-white/70 border-b border-sparrow-gray/40">
      <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-sparrow-gradientStart to-sparrow-gradientEnd flex items-center justify-center text-white text-lg font-semibold">
            SI
          </div>
          <div>
            <p className="text-lg font-semibold text-sparrow-navy brand-font">Sparrow Invest</p>
            <p className="text-xs text-sparrow-navy/60">
              {mode === 'admin' ? 'Admin studio' : 'Personal portfolio journey'}
            </p>
          </div>
        </Link>
        <nav className="hidden md:flex items-center gap-6 text-sm font-medium text-sparrow-navy">
          {scopedLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="px-3 py-2 rounded-xl hover:bg-white/70 text-sparrow-navy"
            >
              {link.label}
            </Link>
          ))}
        </nav>
        <div className="flex items-center gap-3">
          <Link href="/" className="btn-ghost text-sm">Logout</Link>
        </div>
      </div>
    </header>
  );
};

export default Navbar;
