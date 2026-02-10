import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('💳 Creating Transactions for Family Members...\n');

  // Get all family members who don't have transactions
  const clientsWithoutTxns = await prisma.fAClient.findMany({
    where: {
      familyGroupId: { not: null },
      transactions: { none: {} }
    },
    include: {
      holdings: true
    }
  });

  console.log(`Found ${clientsWithoutTxns.length} clients without transactions\n`);

  for (const client of clientsWithoutTxns) {
    console.log(`Creating transactions for ${client.name}...`);

    for (const holding of client.holdings) {
      // Create initial BUY transaction for each holding
      const investedValue = Number(holding.investedValue);
      const units = Number(holding.units);
      const avgNav = Number(holding.avgNav);

      // Create 2-3 transactions per holding to simulate investment history
      const txnCount = Math.floor(Math.random() * 2) + 2; // 2-3 transactions
      const amountPerTxn = investedValue / txnCount;
      const unitsPerTxn = units / txnCount;

      for (let i = 0; i < txnCount; i++) {
        // Create transaction date going back in time
        const txnDate = new Date();
        txnDate.setMonth(txnDate.getMonth() - (txnCount - i) * 3); // Every 3 months

        await prisma.fATransaction.create({
          data: {
            clientId: client.id,
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
      }
    }

    const txnCreated = await prisma.fATransaction.count({ where: { clientId: client.id } });
    console.log(`  ✓ ${client.name}: ${txnCreated} transactions created`);
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('TRANSACTION SUMMARY');
  console.log('='.repeat(60));

  const allClients = await prisma.fAClient.findMany({
    where: { familyGroupId: { not: null } },
    include: {
      _count: { select: { transactions: true, holdings: true } }
    },
    orderBy: { name: 'asc' }
  });

  console.log('\nClient'.padEnd(25) + '| Holdings | Transactions');
  console.log('-'.repeat(60));

  let totalTxns = 0;
  allClients.forEach(c => {
    totalTxns += c._count.transactions;
    console.log(
      c.name.padEnd(25) + '| ' +
      String(c._count.holdings).padStart(8) + ' | ' +
      String(c._count.transactions).padStart(12)
    );
  });

  console.log('-'.repeat(60));
  console.log('TOTAL'.padEnd(25) + '|          | ' + String(totalTxns).padStart(12));
  console.log('\n✅ Transactions created successfully!');

  await prisma.$disconnect();
}

main().catch(e => {
  console.error('Error:', e);
  process.exit(1);
});
