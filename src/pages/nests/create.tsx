import { useMemo } from 'react';
import { useRouter } from 'next/router';
import Navbar from '@/components/layout/Navbar';
import Footer from '@/components/layout/Footer';
import PageHeader from '@/components/layout/PageHeader';
import CreateNestPage from '@/components/creator/CreateNestPage';

const CreateNest = () => {
  const router = useRouter();
  const mode = useMemo(() => {
    const rawMode = Array.isArray(router.query.mode) ? router.query.mode[0] : router.query.mode;
    return rawMode === 'admin' ? 'admin' : 'user';
  }, [router.query.mode]);

  return (
    <div className="page-shell">
      <Navbar mode={mode} />
      <main className="max-w-7xl mx-auto px-6 py-10 space-y-8">
        <PageHeader
          title={mode === 'admin' ? 'Investor profile studio' : 'Investor profile'}
          subtitle={
            mode === 'admin'
              ? 'Audit investor profiles, persona matches, and profile completeness.'
              : 'Build a detailed investor profile to unlock AI-powered personas and portfolio mixes.'
          }
          actions={<button className="btn-primary">{mode === 'admin' ? 'Export profiles' : 'Save profile'}</button>}
        />
        <CreateNestPage mode={mode} />
      </main>
      <Footer />
    </div>
  );
};

export default CreateNest;
