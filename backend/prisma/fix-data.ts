import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Mapping of current holding fund codes to actual SchemePlan mfapiSchemeCodes in our database
const FUND_CODE_MAPPING: Record<string, { mfapiCode: number; name: string; category: string }> = {
  // Original codes that need replacement -> actual codes in our system
  '119551': { mfapiCode: 120465, name: 'Axis Large Cap Fund - Direct Plan - Growth', category: 'Large Cap' },
  '120503': { mfapiCode: 120503, name: 'Axis ELSS Tax Saver Fund - Direct Plan - Growth', category: 'ELSS' },
  '118834': { mfapiCode: 118834, name: 'Mirae Asset Large & Midcap Fund - Direct Plan', category: 'Large & Mid Cap' },
  '120716': { mfapiCode: 120716, name: 'UTI Nifty 50 Index Fund - Direct Growth', category: 'Index' },
  '119598': { mfapiCode: 120505, name: 'Axis Midcap Fund - Direct Plan - Growth', category: 'Mid Cap' },
  '118989': { mfapiCode: 120002, name: 'BNP Paribas Mid Cap Fund - Direct Plan - Growth', category: 'Mid Cap' },
  '120505': { mfapiCode: 120505, name: 'Axis Midcap Fund - Direct Plan - Growth', category: 'Mid Cap' },
  '122639': { mfapiCode: 125354, name: 'Axis Small Cap Fund - Direct Plan - Growth', category: 'Small Cap' },
  '119028': { mfapiCode: 119019, name: 'DSP Aggressive Hybrid Fund - Direct Plan - Growth', category: 'Hybrid' },
  '118632': { mfapiCode: 120564, name: 'Aditya Birla Sun Life Flexi Cap Fund - Direct Growth', category: 'Flexi Cap' },
  '120578': { mfapiCode: 120505, name: 'Axis Midcap Fund - Direct Plan - Growth', category: 'Mid Cap' },
  '135781': { mfapiCode: 125354, name: 'Axis Small Cap Fund - Direct Plan - Growth', category: 'Small Cap' },
  '125354': { mfapiCode: 125354, name: 'Axis Small Cap Fund - Direct Plan - Growth', category: 'Small Cap' },
  '125492': { mfapiCode: 120564, name: 'Aditya Birla Sun Life Flexi Cap Fund - Direct Growth', category: 'Flexi Cap' },
  '125497': { mfapiCode: 119564, name: 'Aditya Birla Sun Life Focused Fund - Direct Growth', category: 'Focused' },
  '119062': { mfapiCode: 119528, name: 'Aditya Birla Sun Life Large Cap Fund - Direct Growth', category: 'Large Cap' },
  '119364': { mfapiCode: 119350, name: 'BANK OF INDIA Large & Mid Cap Fund Direct Plan', category: 'Large & Mid Cap' },
  '120841': { mfapiCode: 120524, name: 'Axis Multi Asset Allocation Fund - Direct Growth', category: 'Multi Asset' },
};

async function fixHoldingFundCodes() {
  console.log('\n1. FIXING HOLDING FUND CODES');
  console.log('='.repeat(80));

  const holdings = await prisma.fAHolding.findMany();
  let updatedCount = 0;

  for (const holding of holdings) {
    const mapping = FUND_CODE_MAPPING[holding.fundSchemeCode];
    if (mapping && holding.fundSchemeCode !== String(mapping.mfapiCode)) {
      // Find the SchemePlan to link
      const schemePlan = await prisma.schemePlan.findFirst({
        where: { mfapiSchemeCode: mapping.mfapiCode }
      });

      await prisma.fAHolding.update({
        where: { id: holding.id },
        data: {
          fundSchemeCode: String(mapping.mfapiCode),
          fundName: mapping.name,
          fundCategory: mapping.category,
          schemePlanId: schemePlan?.id || null,
        }
      });

      console.log(`  ✓ Updated: ${holding.fundSchemeCode} -> ${mapping.mfapiCode} (${mapping.name.substring(0, 40)})`);
      updatedCount++;
    }
  }

  console.log(`\nUpdated ${updatedCount} holdings with correct fund codes.`);
}

async function createMissingTransactions() {
  console.log('\n2. CREATING MISSING TRANSACTIONS');
  console.log('='.repeat(80));

  // Get all holdings
  const holdings = await prisma.fAHolding.findMany({
    include: { client: { select: { name: true } } }
  });

  let txnCreated = 0;

  for (const holding of holdings) {
    // Check if transactions exist for this holding
    const existingTxns = await prisma.fATransaction.findMany({
      where: {
        clientId: holding.clientId,
        fundSchemeCode: holding.fundSchemeCode,
      }
    });

    if (existingTxns.length === 0) {
      // Create 2-3 transactions for this holding
      const investedValue = Number(holding.investedValue);
      const units = Number(holding.units);
      const avgNav = Number(holding.avgNav);

      const txnCount = Math.floor(Math.random() * 2) + 2;
      const amountPerTxn = investedValue / txnCount;
      const unitsPerTxn = units / txnCount;

      for (let i = 0; i < txnCount; i++) {
        const txnDate = new Date();
        txnDate.setMonth(txnDate.getMonth() - (txnCount - i) * 3);

        await prisma.fATransaction.create({
          data: {
            clientId: holding.clientId,
            type: i === 0 ? 'BUY' : 'SIP',
            fundName: holding.fundName,
            fundSchemeCode: holding.fundSchemeCode,
            fundCategory: holding.fundCategory,
            folioNumber: holding.folioNumber,
            amount: amountPerTxn,
            units: unitsPerTxn,
            nav: avgNav,
            status: 'COMPLETED',
            paymentMode: i === 0 ? 'NETBANKING' : 'MANDATE',
            date: txnDate,
          }
        });
        txnCreated++;
      }
      console.log(`  ✓ Created ${txnCount} txns for ${holding.client.name} - ${holding.fundName.substring(0, 30)}`);
    }
  }

  console.log(`\nCreated ${txnCreated} new transactions.`);
}

async function fixAdvisorMapping() {
  console.log('\n3. FIXING ADVISOR MAPPING');
  console.log('='.repeat(80));

  // Get the main advisor
  const advisor = await prisma.user.findFirst({
    where: { email: 'advisor@sparrowinvest.com' }
  });

  if (!advisor) {
    console.log('  ⚠ Advisor not found');
    return;
  }

  // Find clients with unknown/null advisors
  const clientsWithBadAdvisor = await prisma.fAClient.findMany({
    where: {
      OR: [
        { advisorId: { not: advisor.id } },
      ]
    },
    include: { advisor: { select: { email: true } } }
  });

  // Filter to those with advisors that don't match our known advisors
  const knownAdvisorIds = [
    advisor.id,
    (await prisma.user.findFirst({ where: { email: 'admin@sparrowinvest.com' } }))?.id,
    (await prisma.user.findFirst({ where: { email: 'admin@sparrow.com' } }))?.id,
  ].filter(Boolean);

  let fixedCount = 0;
  for (const client of clientsWithBadAdvisor) {
    if (!knownAdvisorIds.includes(client.advisorId)) {
      await prisma.fAClient.update({
        where: { id: client.id },
        data: { advisorId: advisor.id }
      });
      console.log(`  ✓ Fixed advisor for ${client.name}: ${client.advisor?.email || 'unknown'} -> ${advisor.email}`);
      fixedCount++;
    }
  }

  console.log(`\nFixed ${fixedCount} clients with unknown advisors.`);
}

async function createFamilySIPs() {
  console.log('\n4. CREATING SIPS FOR FAMILY MEMBERS');
  console.log('='.repeat(80));

  // Get family members without SIPs (excluding heads who already have SIPs)
  const membersWithoutSIPs = await prisma.fAClient.findMany({
    where: {
      familyGroupId: { not: null },
      sips: { none: {} }
    },
    include: {
      holdings: true,
      _count: { select: { sips: true } }
    }
  });

  console.log(`Found ${membersWithoutSIPs.length} family members without SIPs`);

  let sipCreated = 0;

  for (const member of membersWithoutSIPs) {
    if (member.holdings.length === 0) continue;

    // Create 1-2 SIPs for each member based on their holdings
    const holdingsForSIP = member.holdings.slice(0, 2);

    for (const holding of holdingsForSIP) {
      const sipAmount = member.riskProfile === 'CONSERVATIVE' ? 5000 :
                        member.riskProfile === 'MODERATE' ? 10000 : 15000;

      const startDate = new Date();
      startDate.setMonth(startDate.getMonth() - 6); // Started 6 months ago

      const nextSipDate = new Date();
      nextSipDate.setDate(10); // 10th of next month
      if (nextSipDate <= new Date()) {
        nextSipDate.setMonth(nextSipDate.getMonth() + 1);
      }

      await prisma.fASIP.create({
        data: {
          clientId: member.id,
          fundName: holding.fundName,
          fundSchemeCode: holding.fundSchemeCode,
          folioNumber: holding.folioNumber,
          amount: sipAmount,
          frequency: 'MONTHLY',
          sipDate: 10,
          startDate: startDate,
          status: 'ACTIVE',
          totalInstallments: 60, // 5 year SIP
          completedInstallments: 6,
          totalInvested: sipAmount * 6,
          currentValue: sipAmount * 6 * 1.08, // 8% gain
          returns: sipAmount * 6 * 0.08,
          returnsPct: 8,
          nextSipDate: nextSipDate,
          lastSipDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
        }
      });

      console.log(`  ✓ Created SIP for ${member.name}: Rs.${sipAmount} in ${holding.fundName.substring(0, 30)}`);
      sipCreated++;
    }
  }

  console.log(`\nCreated ${sipCreated} new SIPs.`);
}

async function linkHoldingsToSchemePlans() {
  console.log('\n5. LINKING HOLDINGS TO SCHEME PLANS');
  console.log('='.repeat(80));

  const holdings = await prisma.fAHolding.findMany({
    where: { schemePlanId: null }
  });

  let linkedCount = 0;

  for (const holding of holdings) {
    const mfapiCode = parseInt(holding.fundSchemeCode, 10);
    const schemePlan = await prisma.schemePlan.findFirst({
      where: { mfapiSchemeCode: mfapiCode }
    });

    if (schemePlan) {
      await prisma.fAHolding.update({
        where: { id: holding.id },
        data: { schemePlanId: schemePlan.id }
      });
      linkedCount++;
    }
  }

  console.log(`Linked ${linkedCount} holdings to SchemePlan records.`);
}

async function printSummary() {
  console.log('\n' + '='.repeat(80));
  console.log('FIX SUMMARY');
  console.log('='.repeat(80));

  const stats = {
    totalClients: await prisma.fAClient.count(),
    familyClients: await prisma.fAClient.count({ where: { familyGroupId: { not: null } } }),
    totalHoldings: await prisma.fAHolding.count(),
    linkedHoldings: await prisma.fAHolding.count({ where: { schemePlanId: { not: null } } }),
    totalTransactions: await prisma.fATransaction.count(),
    totalSIPs: await prisma.fASIP.count(),
    activeSIPs: await prisma.fASIP.count({ where: { status: 'ACTIVE' } }),
  };

  console.log(`\n📊 Current State:`);
  console.log(`   Clients: ${stats.totalClients} (${stats.familyClients} in families)`);
  console.log(`   Holdings: ${stats.totalHoldings} (${stats.linkedHoldings} linked to SchemePlan)`);
  console.log(`   Transactions: ${stats.totalTransactions}`);
  console.log(`   SIPs: ${stats.totalSIPs} (${stats.activeSIPs} active)`);
}

async function main() {
  console.log('='.repeat(80));
  console.log('                    DATA FIX SCRIPT');
  console.log('='.repeat(80));

  try {
    await fixHoldingFundCodes();
    await createMissingTransactions();
    await fixAdvisorMapping();
    await createFamilySIPs();
    await linkHoldingsToSchemePlans();
    await printSummary();

    console.log('\n✅ All fixes applied successfully!');
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
