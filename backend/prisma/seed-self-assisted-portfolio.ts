import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

const prisma = new PrismaClient();

// Comprehensive list of mutual funds with realistic data
const MUTUAL_FUNDS = [
  // Large Cap
  { code: '120503', name: 'Axis Bluechip Fund - Direct Growth', category: 'Large Cap', assetClass: 'Equity', nav: 52.34, risk: 'Moderate' },
  { code: '119598', name: 'Mirae Asset Large Cap Fund - Direct Growth', category: 'Large Cap', assetClass: 'Equity', nav: 98.67, risk: 'Moderate' },
  { code: '118989', name: 'SBI Blue Chip Fund - Direct Growth', category: 'Large Cap', assetClass: 'Equity', nav: 78.45, risk: 'Moderate' },

  // Flexi Cap
  { code: '125497', name: 'Parag Parikh Flexi Cap Fund - Direct Growth', category: 'Flexi Cap', assetClass: 'Equity', nav: 68.45, risk: 'Moderate' },
  { code: '122639', name: 'HDFC Flexi Cap Fund - Direct Growth', category: 'Flexi Cap', assetClass: 'Equity', nav: 41.23, risk: 'Moderate' },
  { code: '120578', name: 'UTI Flexi Cap Fund - Direct Growth', category: 'Flexi Cap', assetClass: 'Equity', nav: 285.67, risk: 'Moderate' },

  // Mid Cap
  { code: '119062', name: 'Axis Midcap Fund - Direct Growth', category: 'Mid Cap', assetClass: 'Equity', nav: 89.34, risk: 'High' },
  { code: '120505', name: 'Kotak Emerging Equity Fund - Direct Growth', category: 'Mid Cap', assetClass: 'Equity', nav: 95.67, risk: 'High' },
  { code: '118632', name: 'HDFC Mid Cap Opportunities Fund - Direct Growth', category: 'Mid Cap', assetClass: 'Equity', nav: 145.23, risk: 'High' },

  // Small Cap
  { code: '135781', name: 'Nippon India Small Cap Fund - Direct Growth', category: 'Small Cap', assetClass: 'Equity', nav: 142.56, risk: 'Very High' },
  { code: '125354', name: 'SBI Small Cap Fund - Direct Growth', category: 'Small Cap', assetClass: 'Equity', nav: 165.78, risk: 'Very High' },
  { code: '119028', name: 'Axis Small Cap Fund - Direct Growth', category: 'Small Cap', assetClass: 'Equity', nav: 85.34, risk: 'Very High' },

  // ELSS (Tax Saving)
  { code: '120716', name: 'Axis Long Term Equity Fund - Direct Growth', category: 'ELSS', assetClass: 'Equity', nav: 78.45, risk: 'High' },
  { code: '119551', name: 'Mirae Asset Tax Saver Fund - Direct Growth', category: 'ELSS', assetClass: 'Equity', nav: 42.89, risk: 'High' },

  // Hybrid
  { code: '118834', name: 'HDFC Balanced Advantage Fund - Direct Growth', category: 'Balanced Advantage', assetClass: 'Hybrid', nav: 45.67, risk: 'Moderate' },
  { code: '125492', name: 'ICICI Pru Balanced Advantage Fund - Direct Growth', category: 'Balanced Advantage', assetClass: 'Hybrid', nav: 58.34, risk: 'Moderate' },
  { code: '119364', name: 'SBI Equity Hybrid Fund - Direct Growth', category: 'Aggressive Hybrid', assetClass: 'Hybrid', nav: 235.67, risk: 'Moderate' },

  // Debt Funds
  { code: '119237', name: 'ICICI Pru Corporate Bond Fund - Direct Growth', category: 'Corporate Bond', assetClass: 'Debt', nav: 26.78, risk: 'Low' },
  { code: '120841', name: 'SBI Liquid Fund - Direct Growth', category: 'Liquid', assetClass: 'Debt', nav: 3456.78, risk: 'Very Low' },
  { code: '118545', name: 'HDFC Short Term Debt Fund - Direct Growth', category: 'Short Duration', assetClass: 'Debt', nav: 28.45, risk: 'Low' },
];

// Self-assisted client profiles with detailed information
const SELF_ASSISTED_CLIENTS = [
  {
    name: 'Rohit Bansal',
    email: 'rohit.bansal@demo.com',
    phone: '+91 87654 11111',
    pan: 'ABCPB1234K',
    city: 'Gurugram',
    state: 'Haryana',
    pincode: '122001',
    riskProfile: 'AGGRESSIVE',
    age: 28,
    profession: 'Software Engineer',
    monthlyIncome: 180000,
    investmentStyle: 'growth', // More equity, small caps
  },
  {
    name: 'Megha Kulkarni',
    email: 'megha.kulkarni@demo.com',
    phone: '+91 87654 22222',
    pan: 'ABCPK2345L',
    city: 'Pune',
    state: 'Maharashtra',
    pincode: '411001',
    riskProfile: 'MODERATE',
    age: 35,
    profession: 'Marketing Manager',
    monthlyIncome: 150000,
    investmentStyle: 'balanced', // Mix of equity and hybrid
  },
  {
    name: 'Varun Kapoor',
    email: 'varun.kapoor@demo.com',
    phone: '+91 87654 33333',
    pan: 'ABCPK3456M',
    city: 'Noida',
    state: 'Uttar Pradesh',
    pincode: '201301',
    riskProfile: 'AGGRESSIVE',
    age: 31,
    profession: 'Entrepreneur',
    monthlyIncome: 250000,
    investmentStyle: 'growth',
  },
  {
    name: 'Shreya Menon',
    email: 'shreya.menon@demo.com',
    phone: '+91 87654 44444',
    pan: 'ABCPM4567N',
    city: 'Kochi',
    state: 'Kerala',
    pincode: '682001',
    riskProfile: 'CONSERVATIVE',
    age: 45,
    profession: 'Teacher',
    monthlyIncome: 80000,
    investmentStyle: 'conservative', // More debt and hybrid
  },
  {
    name: 'Akash Jain',
    email: 'akash.jain@demo.com',
    phone: '+91 87654 55555',
    pan: 'ABCPJ5678O',
    city: 'Jaipur',
    state: 'Rajasthan',
    pincode: '302001',
    riskProfile: 'MODERATE',
    age: 38,
    profession: 'Business Owner',
    monthlyIncome: 200000,
    investmentStyle: 'balanced',
  },
  {
    name: 'Pooja Reddy',
    email: 'pooja.reddy@demo.com',
    phone: '+91 87654 66666',
    pan: 'ABCPR6789P',
    city: 'Hyderabad',
    state: 'Telangana',
    pincode: '500001',
    riskProfile: 'AGGRESSIVE',
    age: 29,
    profession: 'Data Scientist',
    monthlyIncome: 200000,
    investmentStyle: 'growth',
  },
  {
    name: 'Nikhil Agarwal',
    email: 'nikhil.agarwal@demo.com',
    phone: '+91 87654 77777',
    pan: 'ABCPA7890Q',
    city: 'Kolkata',
    state: 'West Bengal',
    pincode: '700001',
    riskProfile: 'MODERATE',
    age: 42,
    profession: 'CA',
    monthlyIncome: 175000,
    investmentStyle: 'balanced',
  },
  {
    name: 'Tanvi Saxena',
    email: 'tanvi.saxena@demo.com',
    phone: '+91 87654 88888',
    pan: 'ABCPS8901R',
    city: 'Lucknow',
    state: 'Uttar Pradesh',
    pincode: '226001',
    riskProfile: 'CONSERVATIVE',
    age: 52,
    profession: 'Retired Govt. Officer',
    monthlyIncome: 60000,
    investmentStyle: 'conservative',
  },
  {
    name: 'Arjun Malhotra',
    email: 'arjun.malhotra@demo.com',
    phone: '+91 87654 99999',
    pan: 'ABCPM9012S',
    city: 'Chandigarh',
    state: 'Punjab',
    pincode: '160001',
    riskProfile: 'AGGRESSIVE',
    age: 26,
    profession: 'Startup Founder',
    monthlyIncome: 300000,
    investmentStyle: 'growth',
  },
  {
    name: 'Divya Chatterjee',
    email: 'divya.chatterjee@demo.com',
    phone: '+91 87655 11111',
    pan: 'ABCPC0123T',
    city: 'Kolkata',
    state: 'West Bengal',
    pincode: '700020',
    riskProfile: 'MODERATE',
    age: 33,
    profession: 'Doctor',
    monthlyIncome: 160000,
    investmentStyle: 'balanced',
  },
];

// Get funds based on investment style
function getFundsForStyle(style: string): typeof MUTUAL_FUNDS {
  switch (style) {
    case 'growth':
      // More equity, mid & small caps
      return MUTUAL_FUNDS.filter(f =>
        ['Large Cap', 'Flexi Cap', 'Mid Cap', 'Small Cap', 'ELSS'].includes(f.category)
      );
    case 'conservative':
      // More debt and hybrid
      return MUTUAL_FUNDS.filter(f =>
        ['Large Cap', 'Balanced Advantage', 'Aggressive Hybrid', 'Corporate Bond', 'Liquid', 'Short Duration'].includes(f.category)
      );
    case 'balanced':
    default:
      // Mix of everything
      return MUTUAL_FUNDS.filter(f =>
        ['Large Cap', 'Flexi Cap', 'Mid Cap', 'Balanced Advantage', 'ELSS', 'Corporate Bond'].includes(f.category)
      );
  }
}

// Generate folio number
function generateFolioNumber(): string {
  return `${Math.floor(1000000000 + Math.random() * 9000000000)}`;
}

// Generate order ID
function generateOrderId(): string {
  return `ORD${Date.now().toString(36).toUpperCase()}${Math.random().toString(36).substring(2, 6).toUpperCase()}`;
}

// Type definitions
interface HoldingData {
  holding: any;
  fund: typeof MUTUAL_FUNDS[0];
  folioNumber: string;
  purchaseDate: Date;
  allocation: number;
}

interface SIPData {
  sip: any;
  fund: typeof MUTUAL_FUNDS[0];
}

// Create holdings for a client
async function createHoldingsForClient(clientId: string, style: string, investmentAmount: number): Promise<HoldingData[]> {
  const funds = getFundsForStyle(style);
  const shuffledFunds = funds.sort(() => Math.random() - 0.5);
  const holdingsCount = style === 'growth' ? 8 : style === 'conservative' ? 5 : 6;
  const selectedFunds = shuffledFunds.slice(0, holdingsCount);

  const holdings: HoldingData[] = [];
  let remainingAmount = investmentAmount;

  for (let i = 0; i < selectedFunds.length; i++) {
    const fund = selectedFunds[i];
    const isLast = i === selectedFunds.length - 1;

    // Allocate amount (last fund gets remaining)
    const allocation = isLast ? remainingAmount : Math.floor(remainingAmount * (0.15 + Math.random() * 0.2));
    remainingAmount -= allocation;

    const folioNumber = generateFolioNumber();
    const avgNav = fund.nav * (0.85 + Math.random() * 0.15); // Bought at 85-100% of current NAV
    const units = allocation / avgNav;
    const currentValue = units * fund.nav;
    const absoluteGain = currentValue - allocation;
    const absoluteGainPct = (absoluteGain / allocation) * 100;

    // Random purchase date (6 months to 3 years ago)
    const purchaseDate = new Date();
    purchaseDate.setMonth(purchaseDate.getMonth() - Math.floor(6 + Math.random() * 30));

    const holding = await prisma.fAHolding.create({
      data: {
        clientId,
        fundName: fund.name,
        fundSchemeCode: fund.code,
        fundCategory: fund.category,
        assetClass: fund.assetClass,
        folioNumber,
        units,
        avgNav,
        currentNav: fund.nav,
        investedValue: allocation,
        currentValue,
        absoluteGain,
        absoluteGainPct,
        xirr: 8 + Math.random() * 20, // 8% to 28% XIRR
        lastTxnDate: purchaseDate,
      }
    });

    holdings.push({ holding, fund, folioNumber, purchaseDate, allocation });
  }

  return holdings;
}

// Create SIPs for a client
async function createSIPsForClient(clientId: string, style: string, monthlySipBudget: number): Promise<SIPData[]> {
  const funds = getFundsForStyle(style);
  const sipFunds = funds.filter(f => f.assetClass === 'Equity' || f.category === 'Balanced Advantage');
  const shuffledFunds = sipFunds.sort(() => Math.random() - 0.5);
  const sipCount = style === 'growth' ? 4 : style === 'conservative' ? 2 : 3;
  const selectedFunds = shuffledFunds.slice(0, sipCount);

  const sips: SIPData[] = [];
  let remainingBudget = monthlySipBudget;

  for (let i = 0; i < selectedFunds.length; i++) {
    const fund = selectedFunds[i];
    const isLast = i === selectedFunds.length - 1;

    // Round to nearest 500
    const sipAmount = isLast
      ? Math.round(remainingBudget / 500) * 500
      : Math.round((remainingBudget * (0.25 + Math.random() * 0.2)) / 500) * 500;
    remainingBudget -= sipAmount;

    if (sipAmount < 500) continue;

    const sipDate = [1, 5, 10, 15, 20][Math.floor(Math.random() * 5)];
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - Math.floor(3 + Math.random() * 18)); // 3 to 21 months ago

    const completedInstallments = Math.floor((Date.now() - startDate.getTime()) / (30 * 24 * 60 * 60 * 1000));
    const totalInvested = completedInstallments * sipAmount;
    const returns = totalInvested * (0.06 + Math.random() * 0.18); // 6% to 24% returns

    const nextSipDate = new Date();
    if (nextSipDate.getDate() >= sipDate) {
      nextSipDate.setMonth(nextSipDate.getMonth() + 1);
    }
    nextSipDate.setDate(sipDate);

    const lastSipDate = new Date();
    lastSipDate.setDate(sipDate);
    if (lastSipDate > new Date()) {
      lastSipDate.setMonth(lastSipDate.getMonth() - 1);
    }

    const sip = await prisma.fASIP.create({
      data: {
        clientId,
        fundName: fund.name,
        fundSchemeCode: fund.code,
        folioNumber: generateFolioNumber(),
        amount: sipAmount,
        frequency: 'MONTHLY',
        sipDate,
        startDate,
        status: 'ACTIVE',
        totalInstallments: 120, // 10 years
        completedInstallments,
        totalInvested,
        currentValue: totalInvested + returns,
        returns,
        returnsPct: (returns / totalInvested) * 100,
        nextSipDate,
        lastSipDate: completedInstallments > 0 ? lastSipDate : null,
        stepUpPercent: Math.random() > 0.5 ? 10 : null,
        stepUpFrequency: Math.random() > 0.5 ? 'Yearly' : null,
      }
    });

    sips.push({ sip, fund });
  }

  return sips;
}

// Create transaction history for a client
async function createTransactionsForClient(
  clientId: string,
  holdings: HoldingData[],
  sips: SIPData[]
): Promise<any[]> {
  const transactions: any[] = [];

  // Create initial purchase transactions for each holding
  for (const { holding, fund, folioNumber, purchaseDate, allocation } of holdings) {
    // Initial purchase
    const initialTxn = await prisma.fATransaction.create({
      data: {
        clientId,
        fundName: fund.name,
        fundSchemeCode: fund.code,
        fundCategory: fund.category,
        type: 'BUY',
        amount: allocation * 0.6, // 60% initial
        units: (allocation * 0.6) / (fund.nav * 0.9),
        nav: fund.nav * 0.9,
        status: 'COMPLETED',
        date: purchaseDate,
        folioNumber,
        orderId: generateOrderId(),
        paymentMode: ['Net Banking', 'UPI', 'NACH'][Math.floor(Math.random() * 3)],
      }
    });
    transactions.push(initialTxn);

    // Additional purchases (1-3 more)
    const additionalCount = 1 + Math.floor(Math.random() * 3);
    for (let i = 0; i < additionalCount; i++) {
      const txnDate = new Date(purchaseDate);
      txnDate.setMonth(txnDate.getMonth() + Math.floor(1 + Math.random() * 6));

      if (txnDate > new Date()) continue;

      const txnAmount = Math.floor(allocation * (0.1 + Math.random() * 0.15));
      const navAtPurchase = fund.nav * (0.92 + Math.random() * 0.1);

      const additionalTxn = await prisma.fATransaction.create({
        data: {
          clientId,
          fundName: fund.name,
          fundSchemeCode: fund.code,
          fundCategory: fund.category,
          type: 'BUY',
          amount: txnAmount,
          units: txnAmount / navAtPurchase,
          nav: navAtPurchase,
          status: 'COMPLETED',
          date: txnDate,
          folioNumber,
          orderId: generateOrderId(),
          paymentMode: ['Net Banking', 'UPI', 'NACH'][Math.floor(Math.random() * 3)],
        }
      });
      transactions.push(additionalTxn);
    }
  }

  // Create SIP transactions (last 6-12 months)
  for (const { sip, fund } of sips) {
    const sipTransactions = Math.min(sip.completedInstallments, 12);

    for (let i = 0; i < sipTransactions; i++) {
      const txnDate = new Date();
      txnDate.setMonth(txnDate.getMonth() - i);
      txnDate.setDate(sip.sipDate);

      const navAtSip = fund.nav * (0.95 + Math.random() * 0.1);

      const sipTxn = await prisma.fATransaction.create({
        data: {
          clientId,
          fundName: fund.name,
          fundSchemeCode: fund.code,
          fundCategory: fund.category,
          type: 'SIP',
          amount: sip.amount,
          units: Number(sip.amount) / navAtSip,
          nav: navAtSip,
          status: 'COMPLETED',
          date: txnDate,
          folioNumber: sip.folioNumber,
          orderId: generateOrderId(),
          paymentMode: 'NACH',
          sipId: sip.id,
        }
      });
      transactions.push(sipTxn);
    }
  }

  return transactions;
}

async function main() {
  console.log('🚀 Creating robust portfolios for self-assisted clients...\n');

  // First, get or create the self-service advisor
  let selfServiceAdvisor = await prisma.user.findFirst({
    where: { email: 'self-service@sparrow-invest.com' }
  });

  if (!selfServiceAdvisor) {
    selfServiceAdvisor = await prisma.user.create({
      data: {
        email: 'self-service@sparrow-invest.com',
        passwordHash: await bcrypt.hash('SelfService@123', 10),
        role: 'advisor',
        isActive: true,
        isVerified: true,
        profile: {
          create: {
            name: 'Self-Service Platform',
            city: 'Mumbai',
          },
        },
      },
    });
  }

  console.log(`✅ Self-Service Platform Advisor: ${selfServiceAdvisor.id}\n`);

  // Process each self-assisted client
  for (const clientData of SELF_ASSISTED_CLIENTS) {
    console.log(`\n👤 Processing: ${clientData.name}`);
    console.log(`   Email: ${clientData.email}`);
    console.log(`   Risk Profile: ${clientData.riskProfile}`);
    console.log(`   Investment Style: ${clientData.investmentStyle}`);

    // Step 1: Create or get User account
    let user = await prisma.user.findFirst({
      where: { email: clientData.email }
    });

    if (!user) {
      const userPassword = await bcrypt.hash('Demo@123', 10);
      user = await prisma.user.create({
        data: {
          email: clientData.email,
          phone: clientData.phone,
          passwordHash: userPassword,
          role: 'investor',
          isActive: true,
          isVerified: true,
          profile: {
            create: {
              name: clientData.name,
              city: clientData.city,
              age: clientData.age,
              riskTolerance: clientData.riskProfile === 'AGGRESSIVE' ? 'High' : clientData.riskProfile === 'MODERATE' ? 'Medium' : 'Low',
            },
          },
        },
      });
      console.log(`   ✓ Created User account: ${user.id}`);
    } else {
      console.log(`   ✓ Found existing User account: ${user.id}`);
    }

    // Step 2: Create or get FAClient record
    let client = await prisma.fAClient.findFirst({
      where: { email: clientData.email }
    });

    if (!client) {
      client = await prisma.fAClient.create({
        data: {
          advisorId: selfServiceAdvisor.id,
          userId: user.id, // Link to User account for portfolio segregation
          name: clientData.name,
          email: clientData.email,
          phone: clientData.phone,
          pan: clientData.pan,
          city: clientData.city,
          state: clientData.state,
          pincode: clientData.pincode,
          riskProfile: clientData.riskProfile as any,
          status: 'ACTIVE',
          kycStatus: 'VERIFIED',
          dateOfBirth: new Date(new Date().getFullYear() - clientData.age, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1),
          lastActiveAt: new Date(Date.now() - Math.floor(Math.random() * 3) * 24 * 60 * 60 * 1000),
        },
      });
      console.log(`   ✓ Created FAClient record: ${client.id}`);
    } else {
      // Update to ensure userId is linked
      if (!client.userId) {
        await prisma.fAClient.update({
          where: { id: client.id },
          data: { userId: user.id }
        });
        console.log(`   ✓ Linked existing FAClient to User: ${client.id}`);
      } else {
        console.log(`   ✓ Found existing FAClient record: ${client.id}`);
      }
    }

    // Step 3: Clear existing holdings, SIPs, and transactions for fresh data
    await prisma.fATransaction.deleteMany({ where: { clientId: client.id } });
    await prisma.fASIP.deleteMany({ where: { clientId: client.id } });
    await prisma.fAHolding.deleteMany({ where: { clientId: client.id } });
    console.log(`   ✓ Cleared existing portfolio data`);

    // Step 4: Calculate investment amounts based on profile
    const investmentAmount = clientData.monthlyIncome * (12 + Math.floor(Math.random() * 24)); // 1-3 years of savings
    const monthlySipBudget = Math.floor(clientData.monthlyIncome * (0.2 + Math.random() * 0.15)); // 20-35% of income

    // Step 5: Create holdings
    const holdings = await createHoldingsForClient(client.id, clientData.investmentStyle, investmentAmount);
    console.log(`   ✓ Created ${holdings.length} holdings`);

    // Step 6: Create SIPs
    const sips = await createSIPsForClient(client.id, clientData.investmentStyle, monthlySipBudget);
    console.log(`   ✓ Created ${sips.length} active SIPs`);

    // Step 7: Create transactions
    const transactions = await createTransactionsForClient(client.id, holdings, sips);
    console.log(`   ✓ Created ${transactions.length} transactions`);

    // Calculate totals
    const totalInvested = holdings.reduce((sum, h) => sum + h.allocation, 0);
    const totalCurrent = holdings.reduce((sum, h) => sum + Number(h.holding.currentValue), 0);
    const totalGain = totalCurrent - totalInvested;
    const gainPercent = (totalGain / totalInvested) * 100;

    console.log(`   📊 Portfolio Summary:`);
    console.log(`      Total Invested: ₹${totalInvested.toLocaleString('en-IN')}`);
    console.log(`      Current Value:  ₹${Math.round(totalCurrent).toLocaleString('en-IN')}`);
    console.log(`      Gain:           ₹${Math.round(totalGain).toLocaleString('en-IN')} (${gainPercent.toFixed(2)}%)`);
    console.log(`      Monthly SIPs:   ₹${sips.reduce((sum, s) => sum + Number(s.sip.amount), 0).toLocaleString('en-IN')}`);
  }

  // Print summary
  console.log('\n' + '='.repeat(80));
  console.log('📊 FINAL SUMMARY');
  console.log('='.repeat(80));

  const totalClients = await prisma.fAClient.count({ where: { advisorId: selfServiceAdvisor.id } });
  const totalHoldings = await prisma.fAHolding.count({
    where: { client: { advisorId: selfServiceAdvisor.id } }
  });
  const totalSIPs = await prisma.fASIP.count({
    where: { client: { advisorId: selfServiceAdvisor.id }, status: 'ACTIVE' }
  });
  const totalTransactions = await prisma.fATransaction.count({
    where: { client: { advisorId: selfServiceAdvisor.id } }
  });

  console.log(`\n  Self-Assisted Clients: ${totalClients}`);
  console.log(`  Total Holdings:        ${totalHoldings}`);
  console.log(`  Active SIPs:           ${totalSIPs}`);
  console.log(`  Total Transactions:    ${totalTransactions}`);

  console.log('\n📋 CLIENT PORTFOLIO BREAKDOWN:');
  console.log('-'.repeat(80));
  console.log(`${'Name'.padEnd(25)} | ${'User ID'.padEnd(36)} | ${'Client ID'.padEnd(36)} | Holdings`);
  console.log('-'.repeat(80));

  const clients = await prisma.fAClient.findMany({
    where: { advisorId: selfServiceAdvisor.id },
    include: {
      user: { select: { id: true, email: true } },
      holdings: { select: { id: true } },
      sips: { where: { status: 'ACTIVE' }, select: { id: true } },
    }
  });

  for (const client of clients) {
    console.log(`${client.name.padEnd(25)} | ${(client.userId || 'N/A').padEnd(36)} | ${client.id.padEnd(36)} | ${client.holdings.length} holdings, ${client.sips.length} SIPs`);
  }

  console.log('\n✅ Portfolio segregation is ensured via:');
  console.log('   - Each User has a unique userId');
  console.log('   - Each FAClient is linked to a User via userId field');
  console.log('   - getClientPortfolio() in auth.service.ts filters by userId');
  console.log('   - Each user sees ONLY their own holdings/SIPs/transactions\n');

  console.log('🔐 Login Credentials:');
  console.log('   Email: [name]@demo.com');
  console.log('   Password: Demo@123\n');

  await prisma.$disconnect();
}

main().catch((e) => {
  console.error('❌ Error:', e);
  process.exit(1);
});
