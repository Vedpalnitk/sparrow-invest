import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('='.repeat(80));
  console.log('                    COMPLETE DATA AUDIT');
  console.log('='.repeat(80));

  // 1. Get all schemes in the system
  console.log('\n1. SCHEMES IN SYSTEM');
  console.log('-'.repeat(80));
  const schemeCount = await prisma.scheme.count();
  const schemePlanCount = await prisma.schemePlan.count();
  const schemePlans = await prisma.schemePlan.findMany({
    include: { scheme: true },
    where: { mfapiSchemeCode: { not: null } },
    take: 15
  });
  console.log('Total Schemes:', schemeCount);
  console.log('Total Scheme Plans:', schemePlanCount);
  console.log('\nSample scheme plans with MFAPI codes:');
  schemePlans.forEach(sp => {
    console.log('  MFAPI:', String(sp.mfapiSchemeCode).padEnd(8), '| ISIN:', sp.isin, '|', sp.name.substring(0, 40));
  });

  // 2. Check holdings fund codes vs system schemes
  console.log('\n2. HOLDINGS FUND CODE AUDIT');
  console.log('-'.repeat(80));
  const holdings = await prisma.fAHolding.findMany({
    include: { client: { select: { name: true } } }
  });

  const holdingCodes = [...new Set(holdings.map(h => h.fundSchemeCode))];
  console.log('Unique fund codes in holdings:', holdingCodes.length);

  let matchedCount = 0;
  const unmatchedCodes: string[] = [];
  for (const code of holdingCodes) {
    // Try to match with SchemePlan.mfapiSchemeCode (fund codes are MFAPI scheme codes)
    const codeInt = parseInt(code, 10);
    const schemePlan = await prisma.schemePlan.findFirst({
      where: { mfapiSchemeCode: codeInt },
      include: { scheme: true }
    });
    if (schemePlan) {
      matchedCount++;
      console.log('  ✓', code, '->', schemePlan.name.substring(0, 50));
    } else {
      // Also try Scheme.mfapiSchemeCode
      const scheme = await prisma.scheme.findFirst({ where: { mfapiSchemeCode: codeInt } });
      if (scheme) {
        matchedCount++;
        console.log('  ✓', code, '->', scheme.name.substring(0, 50), '(Scheme level)');
      } else {
        unmatchedCodes.push(code);
      }
    }
  }
  console.log('\nMatched with system schemes:', matchedCount);
  console.log('NOT matched (need fixing):', unmatchedCodes.length);
  if (unmatchedCodes.length > 0) {
    console.log('Unmatched codes:', unmatchedCodes.slice(0, 10).join(', '));
  }

  // 3. Family mapping audit
  console.log('\n3. FAMILY MAPPING AUDIT');
  console.log('-'.repeat(80));
  const familyClients = await prisma.fAClient.findMany({
    where: { familyGroupId: { not: null } },
    orderBy: [{ familyGroupId: 'asc' }, { familyRole: 'asc' }]
  });

  const families: Record<string, typeof familyClients> = {};
  familyClients.forEach(c => {
    if (!families[c.familyGroupId!]) families[c.familyGroupId!] = [];
    families[c.familyGroupId!].push(c);
  });

  let familyIssues = 0;
  Object.keys(families).forEach(fid => {
    const members = families[fid];
    const head = members.find(m => m.familyRole === 'SELF');
    console.log('\nFamily:', fid.substring(0, 8) + '...');
    console.log('Head:', head ? head.name : '⚠ MISSING HEAD!');
    if (!head) familyIssues++;

    members.forEach(m => {
      const headCheck = m.familyHeadId === (head ? head.id : null) ? '✓' : '⚠ WRONG';
      if (headCheck !== '✓') familyIssues++;
      console.log('  -', (m.familyRole || '-').padEnd(8), m.name.padEnd(20), '| HeadRef:', headCheck);
    });
  });

  // 4. Advisor mapping audit
  console.log('\n4. ADVISOR MAPPING AUDIT');
  console.log('-'.repeat(80));
  const advisors = await prisma.user.findMany({
    where: { role: { in: ['advisor', 'super_admin'] } },
    select: { id: true, email: true, role: true }
  });
  console.log('Advisors in system:');
  advisors.forEach(a => console.log('  -', a.email, '(' + a.role + ') ID:', a.id));

  const clientsByAdvisor = await prisma.fAClient.groupBy({
    by: ['advisorId'],
    _count: true
  });
  console.log('\nClients by advisor:');
  for (const g of clientsByAdvisor) {
    const adv = advisors.find(a => a.id === g.advisorId);
    console.log('  -', adv ? adv.email : '⚠ UNKNOWN ADVISOR', ':', g._count, 'clients');
  }

  // 5. Holdings vs Transactions consistency
  console.log('\n5. HOLDINGS vs TRANSACTIONS AUDIT');
  console.log('-'.repeat(80));
  const clients = await prisma.fAClient.findMany({
    include: {
      holdings: true,
      transactions: true,
      sips: true
    }
  });

  let txnIssues = 0;
  console.log('Client'.padEnd(22) + '| Holdings | Txns | SIPs | Status');
  console.log('-'.repeat(80));

  clients.forEach(c => {
    const holdingFunds = new Set(c.holdings.map(h => h.fundSchemeCode));
    const txnFunds = new Set(c.transactions.map(t => t.fundSchemeCode));

    const holdingsWithoutTxn = [...holdingFunds].filter(f => !txnFunds.has(f));
    const hasIssue = holdingsWithoutTxn.length > 0;
    if (hasIssue) txnIssues++;

    const status = hasIssue ? '⚠ ' + holdingsWithoutTxn.length + ' holdings without txns' : '✓ OK';
    console.log(
      c.name.padEnd(22) + '| ' +
      String(c.holdings.length).padStart(8) + ' | ' +
      String(c.transactions.length).padStart(4) + ' | ' +
      String(c.sips.length).padStart(4) + ' | ' +
      status
    );
  });

  // 6. SIP audit
  console.log('\n6. SIP AUDIT');
  console.log('-'.repeat(80));
  const sips = await prisma.fASIP.findMany({
    include: { client: { select: { name: true } } }
  });
  console.log('Total SIPs:', sips.length);
  if (sips.length > 0) {
    sips.forEach(s => {
      console.log('  -', s.client.name.padEnd(20), '|', s.fundName.substring(0, 30).padEnd(32), '| Rs.', String(Number(s.amount)).padStart(6), '|', s.status);
    });
  }

  // Summary
  console.log('\n' + '='.repeat(80));
  console.log('AUDIT SUMMARY - ISSUES FOUND');
  console.log('='.repeat(80));
  console.log('1. Fund codes NOT matching system schemes:', unmatchedCodes.length > 0 ? '⚠ YES - ' + unmatchedCodes.length + ' codes' : '✓ OK');
  console.log('2. Family mapping issues:', familyIssues > 0 ? '⚠ YES - ' + familyIssues + ' issues' : '✓ OK');
  console.log('3. Holdings without transactions:', txnIssues > 0 ? '⚠ YES - ' + txnIssues + ' clients' : '✓ OK');
  console.log('4. Family members without SIPs:', sips.length < familyClients.length ? '⚠ YES' : '✓ OK');

  console.log('\n' + '='.repeat(80));
  console.log('ACTION ITEMS:');
  console.log('='.repeat(80));
  console.log('1. Replace all holding fund codes with actual Scheme.amfiCode from database');
  console.log('2. Create transactions for all holdings');
  console.log('3. Create SIPs for family members');
  console.log('4. Link holdings to SchemePlan for fund details');

  await prisma.$disconnect();
}

main().catch(e => {
  console.error('Error:', e);
  process.exit(1);
});
