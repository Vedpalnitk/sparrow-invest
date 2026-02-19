import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

const prisma = new PrismaClient();

// =============================================
// HELPERS
// =============================================

function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  d.setHours(0, 0, 0, 0);
  return d;
}

function daysFromNow(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setHours(0, 0, 0, 0);
  return d;
}

function monthsAgo(n: number): Date {
  const d = new Date();
  d.setMonth(d.getMonth() - n);
  d.setHours(0, 0, 0, 0);
  return d;
}

function periodString(monthsBack: number): string {
  const d = new Date();
  d.setMonth(d.getMonth() - monthsBack);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

function randomBetween(min: number, max: number): number {
  return Math.round((Math.random() * (max - min) + min) * 100) / 100;
}

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

// =============================================
// AMC Provider IDs (from seed-funds.ts)
// =============================================

const AMC_IDS = [
  'hdfc-mutual-fund', 'icici-prudential-mutual-fund', 'sbi-mutual-fund',
  'axis-mutual-fund', 'kotak-mahindra-mutual-fund', 'nippon-india-mutual-fund',
  'mirae-asset-mutual-fund', 'dsp-mutual-fund', 'franklin-templeton-mutual-fund',
  'aditya-birla-sun-life-mutual-fund', 'edelweiss-mutual-fund',
];

const SCHEME_CATEGORIES = ['EQUITY', 'DEBT', 'HYBRID', 'ELSS', 'INDEX', 'LIQUID'];

// =============================================
// FULL SEED FOR A SINGLE ADVISOR
// =============================================

async function seedForAdvisor(advisorId: string, advisorEmail: string, branchPrefix: string) {
  console.log(`\n━━━ Seeding full data for ${advisorEmail} ━━━`);

  // Look up existing clients
  const clients = await prisma.fAClient.findMany({
    where: { advisorId },
    take: 15,
  });
  console.log(`  👥 Found ${clients.length} clients`);

  // Look up existing staff
  const existingStaff = await prisma.fAStaffMember.findMany({
    where: { ownerId: advisorId },
    include: { staffUser: true },
  });
  console.log(`  👤 Found ${existingStaff.length} staff members`);

  // ═══════════════════════════════════════════
  // 1. BRANCHES
  // ═══════════════════════════════════════════
  console.log('  📍 Creating branches...');

  const branchData = [
    { name: `${branchPrefix} - Andheri`, city: 'Mumbai', code: `${branchPrefix}-AND` },
    { name: `${branchPrefix} - Bandra`, city: 'Mumbai', code: `${branchPrefix}-BAN` },
    { name: `${branchPrefix} - Connaught Place`, city: 'Delhi', code: `${branchPrefix}-CP` },
    { name: `${branchPrefix} - Koramangala`, city: 'Bengaluru', code: `${branchPrefix}-KOR` },
    { name: `${branchPrefix} - Hinjawadi`, city: 'Pune', code: `${branchPrefix}-HIN` },
  ];

  const branches: any[] = [];
  for (const b of branchData) {
    const branch = await prisma.branch.upsert({
      where: { id: `BR-${b.code}` },
      update: {},
      create: {
        id: `BR-${b.code}`,
        advisorId,
        name: b.name,
        city: b.city,
        code: b.code,
        isActive: true,
      },
    });
    branches.push(branch);
  }
  console.log(`    ✓ ${branches.length} branches`);

  // ═══════════════════════════════════════════
  // 2. STAFF UPDATES (assign branches, EUINs, roles)
  // ═══════════════════════════════════════════
  if (existingStaff.length > 0) {
    console.log('  👥 Updating staff with branches, EUINs, roles...');
    const staffRoles = ['RM', 'OPERATIONS', 'COMPLIANCE_OFFICER', 'SENIOR_ADVISOR', 'BRANCH_MANAGER'];
    const euinPrefixes = ['E1234', 'E5678', 'E9012', 'E3456', 'E7890'];

    for (let i = 0; i < existingStaff.length; i++) {
      const staff = existingStaff[i];
      const branch = branches[i % branches.length];
      await prisma.fAStaffMember.update({
        where: { id: staff.id },
        data: {
          staffRole: pick(staffRoles) as any,
          euin: `${euinPrefixes[i % euinPrefixes.length]}${String(i + 1).padStart(2, '0')}`,
          euinExpiry: i === 0 ? daysFromNow(15) : daysFromNow(120 + i * 30),
          branchId: branch.id,
        },
      });
    }
    console.log(`    ✓ ${existingStaff.length} staff updated`);
  }

  // ═══════════════════════════════════════════
  // 3. CLIENT UPDATES (assign RMs, tags, importantDates)
  // ═══════════════════════════════════════════
  if (clients.length > 0) {
    console.log('  🏷️  Updating clients with RMs, tags, important dates...');
    const tagOptions = ['HNI', 'NRI', 'Senior Citizen', 'First-time Investor', 'Tax Saver', 'SIP Champion', 'Dormant', 'VIP', 'Corporate'];
    const relationshipTypes = ['Anniversary', 'Birthday', 'Policy Renewal', 'Review Meeting'];

    for (let i = 0; i < clients.length; i++) {
      const client = clients[i];
      const assignedRm = existingStaff.length > 0 ? existingStaff[i % existingStaff.length] : null;

      const numTags = 1 + Math.floor(Math.random() * 3);
      const tags: string[] = [];
      for (let t = 0; t < numTags; t++) {
        const tag = pick(tagOptions);
        if (!tags.includes(tag)) tags.push(tag);
      }

      const importantDates: Record<string, string> = {};
      if (Math.random() > 0.3) {
        importantDates[pick(relationshipTypes)] = daysFromNow(Math.floor(Math.random() * 365)).toISOString().split('T')[0];
      }

      await prisma.fAClient.update({
        where: { id: client.id },
        data: {
          assignedRmId: assignedRm?.id || null,
          tags,
          importantDates: Object.keys(importantDates).length > 0 ? importantDates : undefined,
        },
      });
    }
    console.log(`    ✓ ${clients.length} clients updated`);
  }

  // ═══════════════════════════════════════════
  // 4. COMMISSION RATE MASTER
  // ═══════════════════════════════════════════
  console.log('  💰 Creating commission rate master...');

  const rateCategories = [
    { cat: 'EQUITY', trail: [0.5, 1.2], upfront: [0, 0.5] },
    { cat: 'DEBT', trail: [0.2, 0.5], upfront: [0, 0.1] },
    { cat: 'HYBRID', trail: [0.4, 0.8], upfront: [0, 0.3] },
    { cat: 'ELSS', trail: [0.6, 1.0], upfront: [0, 0.4] },
    { cat: 'LIQUID', trail: [0.05, 0.15], upfront: [0, 0] },
    { cat: 'INDEX', trail: [0.1, 0.3], upfront: [0, 0] },
  ];

  const topAmcs = AMC_IDS.slice(0, 8);
  let rateCount = 0;

  for (const amcId of topAmcs) {
    const amcExists = await prisma.provider.findUnique({ where: { id: amcId } });
    if (!amcExists) continue;

    for (const rc of rateCategories) {
      const id = `CR-${advisorId.slice(0, 8)}-${amcId}-${rc.cat}`;
      await prisma.commissionRateMaster.upsert({
        where: { id },
        update: {},
        create: {
          id,
          advisorId,
          amcId,
          schemeCategory: rc.cat,
          trailRatePercent: randomBetween(rc.trail[0], rc.trail[1]),
          upfrontRatePercent: randomBetween(rc.upfront[0], rc.upfront[1]),
          effectiveFrom: new Date('2025-04-01'),
          effectiveTo: null,
        },
      });
      rateCount++;
    }
  }
  console.log(`    ✓ ${rateCount} commission rates`);

  // ═══════════════════════════════════════════
  // 5. COMMISSION RECORDS (6 months of data)
  // ═══════════════════════════════════════════
  console.log('  📊 Creating commission records...');

  let recordCount = 0;
  for (let m = 0; m < 6; m++) {
    const period = periodString(m);

    for (const amcId of topAmcs.slice(0, 6)) {
      const amcExists = await prisma.provider.findUnique({ where: { id: amcId } });
      if (!amcExists) continue;

      const aumAmount = randomBetween(500000, 5000000);
      const expectedTrail = aumAmount * randomBetween(0.004, 0.01) / 12;
      const variancePct = randomBetween(-0.15, 0.15);
      const actualTrail = m < 2 ? 0 : expectedTrail * (1 + variancePct);

      let status: string;
      if (m < 2) {
        status = 'EXPECTED';
      } else if (Math.abs(variancePct) < 0.05) {
        status = 'RECONCILED';
      } else if (Math.abs(variancePct) > 0.1) {
        status = 'DISCREPANCY';
      } else {
        status = 'RECEIVED';
      }

      await prisma.commissionRecord.upsert({
        where: {
          advisorId_period_amcId: { advisorId, period, amcId },
        },
        update: { aumAmount, expectedTrail, actualTrail, status: status as any },
        create: {
          advisorId,
          period,
          amcId,
          aumAmount,
          expectedTrail,
          actualTrail,
          status: status as any,
        },
      });
      recordCount++;
    }
  }
  console.log(`    ✓ ${recordCount} commission records`);

  // ═══════════════════════════════════════════
  // 6. BROKERAGE UPLOADS (sample history)
  // ═══════════════════════════════════════════
  console.log('  📂 Creating brokerage upload history...');

  const uploadData = [
    { fileName: 'CAMS_Brokerage_Oct2025.csv', source: 'CAMS', records: 142, total: 28450.75, daysBack: 120 },
    { fileName: 'KFintech_Trail_Nov2025.csv', source: 'KFINTECH', records: 98, total: 22180.50, daysBack: 90 },
    { fileName: 'CAMS_Brokerage_Dec2025.csv', source: 'CAMS', records: 156, total: 31200.00, daysBack: 60 },
    { fileName: 'KFintech_Trail_Jan2026.csv', source: 'KFINTECH', records: 103, total: 24500.25, daysBack: 30 },
    { fileName: 'CAMS_Brokerage_Feb2026.csv', source: 'CAMS', records: 148, total: 29750.80, daysBack: 5 },
  ];

  for (const u of uploadData) {
    await prisma.brokerageUpload.create({
      data: {
        advisorId,
        fileName: u.fileName,
        source: u.source as any,
        recordCount: u.records,
        status: 'COMPLETED',
        parsedData: {
          totalBrokerage: u.total,
          summary: {
            'HDFC Mutual Fund': u.total * 0.25,
            'ICICI Prudential': u.total * 0.2,
            'SBI Mutual Fund': u.total * 0.18,
            'Axis Mutual Fund': u.total * 0.15,
            'Kotak Mutual Fund': u.total * 0.12,
            'Others': u.total * 0.1,
          },
        },
        createdAt: daysAgo(u.daysBack),
      },
    });
  }
  console.log(`    ✓ ${uploadData.length} brokerage uploads`);

  // ═══════════════════════════════════════════
  // 7. AUM SNAPSHOTS (90 days of historical data)
  // ═══════════════════════════════════════════
  console.log('  📈 Creating AUM snapshots (90 days)...');

  const baseAum = randomBetween(10000000, 15000000); // 1-1.5 Cr
  let snapshotCount = 0;

  for (let d = 90; d >= 0; d--) {
    const date = daysAgo(d);
    if (date.getDay() === 0 || date.getDay() === 6) continue;

    const growthFactor = 1 + ((90 - d) / 90) * 0.08;
    const dailyVariance = 1 + (Math.random() - 0.5) * 0.02;
    const totalAum = baseAum * growthFactor * dailyVariance;

    const equityPct = 0.55 + Math.random() * 0.05;
    const debtPct = 0.25 + Math.random() * 0.03;
    const hybridPct = 1 - equityPct - debtPct;

    const sipBookBase = 185000;
    const sipGrowth = sipBookBase * (1 + ((90 - d) / 90) * 0.05);
    const netFlows = randomBetween(-200000, 500000);

    await prisma.aUMSnapshot.upsert({
      where: { advisorId_date: { advisorId, date } },
      update: {},
      create: {
        advisorId,
        date,
        totalAum: Math.round(totalAum),
        equityAum: Math.round(totalAum * equityPct),
        debtAum: Math.round(totalAum * debtPct),
        hybridAum: Math.round(totalAum * hybridPct),
        clientCount: clients.length || 5,
        sipBookSize: Math.round(sipGrowth),
        netFlows: Math.round(netFlows),
      },
    });
    snapshotCount++;
  }
  console.log(`    ✓ ${snapshotCount} AUM snapshots`);

  // ═══════════════════════════════════════════
  // 8. CRM TASKS
  // ═══════════════════════════════════════════
  console.log('  📋 Creating CRM tasks...');

  const taskTemplates = [
    { title: 'Follow up on SIP increase', desc: 'Client expressed interest in increasing SIP by 20%', status: 'OPEN', priority: 'HIGH', category: 'FOLLOW_UP', dueOffset: 3 },
    { title: 'Send portfolio review report', desc: 'Quarterly review due, prepare and share report', status: 'OPEN', priority: 'MEDIUM', category: 'REVIEW', dueOffset: 7 },
    { title: 'Discuss tax harvesting opportunity', desc: 'LTCG approaching 1L threshold, need to discuss', status: 'OPEN', priority: 'HIGH', category: 'REVIEW', dueOffset: 5 },
    { title: 'KYC document renewal', desc: 'KYC documents expiring next month, collect updated docs', status: 'OPEN', priority: 'MEDIUM', category: 'KYC_UPDATE', dueOffset: 14 },
    { title: 'New fund recommendation', desc: 'Suggest ELSS allocation for tax saving season', status: 'OPEN', priority: 'LOW', category: 'FOLLOW_UP', dueOffset: 10 },
    { title: 'Process redemption request', desc: 'Client needs partial redemption from debt fund for wedding', status: 'IN_PROGRESS', priority: 'HIGH', category: 'GENERAL', dueOffset: 1 },
    { title: 'Prepare insurance gap analysis', desc: 'Annual insurance review requested', status: 'IN_PROGRESS', priority: 'MEDIUM', category: 'REVIEW', dueOffset: 5 },
    { title: 'Completed SIP registration', desc: 'New SIP of 25K in Axis Bluechip', status: 'COMPLETED', priority: 'HIGH', category: 'GENERAL', dueOffset: -5 },
    { title: 'Birthday greeting sent', desc: 'Sent birthday wishes and gift voucher', status: 'COMPLETED', priority: 'LOW', category: 'GENERAL', dueOffset: -3 },
    { title: 'Risk profile reassessment done', desc: 'Updated risk profile from Moderate to Aggressive', status: 'COMPLETED', priority: 'MEDIUM', category: 'REVIEW', dueOffset: -7 },
    { title: 'Nominee details updated', desc: 'Updated nominee across all folios', status: 'COMPLETED', priority: 'MEDIUM', category: 'KYC_UPDATE', dueOffset: -10 },
    { title: 'Rebalancing discussion overdue', desc: 'Portfolio drifted 8% from target allocation', status: 'OPEN', priority: 'HIGH', category: 'REVIEW', dueOffset: -4 },
    { title: 'Collect address proof', desc: 'Pending address proof for KYC update', status: 'OPEN', priority: 'MEDIUM', category: 'KYC_UPDATE', dueOffset: -8 },
    { title: 'SWP setup pending', desc: 'Client wants monthly SWP from balanced fund', status: 'IN_PROGRESS', priority: 'HIGH', category: 'GENERAL', dueOffset: -2 },
  ];

  let taskCount = 0;
  for (const t of taskTemplates) {
    const client = clients.length > 0 ? clients[taskCount % clients.length] : null;
    const assignee = existingStaff.length > 0 ? existingStaff[taskCount % existingStaff.length] : null;

    await prisma.cRMTask.create({
      data: {
        advisorId,
        clientId: client?.id || null,
        assignedToId: assignee?.id || null,
        title: t.title,
        description: t.desc,
        priority: t.priority as any,
        status: t.status as any,
        category: t.category as any,
        dueDate: t.dueOffset >= 0 ? daysFromNow(t.dueOffset) : daysAgo(Math.abs(t.dueOffset)),
      },
    });
    taskCount++;
  }
  console.log(`    ✓ ${taskCount} CRM tasks`);

  // ═══════════════════════════════════════════
  // 9. CRM ACTIVITY LOG
  // ═══════════════════════════════════════════
  console.log('  📝 Creating CRM activity logs...');

  const activityTemplates = [
    { type: 'CALL', summary: 'Quarterly review call', details: 'Discussed portfolio performance. Client satisfied with 15% returns. Suggested adding small cap allocation.' },
    { type: 'EMAIL', summary: 'Portfolio statement shared', details: 'Sent consolidated portfolio statement for Q3 FY26 via email.' },
    { type: 'MEETING', summary: 'In-person review at branch', details: 'Client visited branch. Reviewed goals, signed SIP mandate for new fund.' },
    { type: 'NOTE', summary: 'Client preference noted', details: 'Client prefers WhatsApp communication over email. No calls after 7 PM.' },
    { type: 'CALL', summary: 'SIP bounce follow-up', details: 'SIP bounced due to insufficient funds. Client will ensure balance by next SIP date.' },
    { type: 'EMAIL', summary: 'Tax saving options shared', details: 'Shared ELSS comparison sheet. Client to decide by end of week.' },
    { type: 'MEETING', summary: 'Goal planning session', details: 'Discussed child education goal. Recommended increasing monthly investment to 50K.' },
    { type: 'CALL', summary: 'New investment discussion', details: 'Client has 10L lump sum to invest. Suggested staggered deployment via STP.' },
    { type: 'NOTE', summary: 'Risk tolerance update', details: 'After discussion, client comfortable moving from Moderate to Moderately Aggressive.' },
    { type: 'EMAIL', summary: 'NFO recommendation', details: 'Shared details of HDFC Defence Fund NFO. Client interested, to confirm by Monday.' },
    { type: 'CALL', summary: 'Market update briefing', details: 'Called to discuss market correction impact. Advised client to stay invested and continue SIPs.' },
    { type: 'MEETING', summary: 'Family wealth review', details: 'Met with client and spouse. Discussed consolidating family portfolio. Spouse to open new folio.' },
    { type: 'NOTE', summary: 'Competitor activity noted', details: 'Client mentioned getting calls from ICICI Direct. Need to ensure regular engagement.' },
    { type: 'CALL', summary: 'Insurance claim assistance', details: 'Helped client initiate health insurance claim process. Shared required document list.' },
    { type: 'EMAIL', summary: 'Annual performance report', details: 'Sent annual portfolio performance vs benchmark comparison report.' },
  ];

  let activityCount = 0;
  for (const a of activityTemplates) {
    const client = clients.length > 0 ? clients[activityCount % clients.length] : null;
    const staff = existingStaff.length > 0 ? existingStaff[activityCount % existingStaff.length] : null;

    await prisma.cRMActivityLog.create({
      data: {
        advisorId,
        clientId: client?.id || null,
        staffId: staff?.id || null,
        type: a.type as any,
        summary: a.summary,
        details: a.details,
        createdAt: daysAgo(Math.floor(Math.random() * 60)),
      },
    });
    activityCount++;
  }
  console.log(`    ✓ ${activityCount} activity logs`);

  // ═══════════════════════════════════════════
  // 10. COMPLIANCE RECORDS
  // ═══════════════════════════════════════════
  console.log('  🛡️  Creating compliance records...');

  const complianceEntries = [
    { type: 'ARN', entityName: 'ARN-12345 (Primary)', expiry: daysFromNow(450), status: 'VALID', notes: 'Primary ARN registration' },
    { type: 'SEBI_REGISTRATION', entityName: 'INA000001234', expiry: daysFromNow(800), status: 'VALID', notes: 'SEBI RIA registration' },
    { type: 'KYC', entityName: 'Client A', expiry: daysFromNow(200), status: 'VALID', notes: 'KYC valid, last updated Jan 2026' },
    { type: 'KYC', entityName: 'Client B', expiry: daysFromNow(300), status: 'VALID', notes: 'KYC verified via CAMS KRA' },
    { type: 'EUIN', entityName: 'Staff EUIN (E123401)', expiry: daysFromNow(120), status: 'VALID', notes: 'Staff EUIN active' },
    { type: 'INSURANCE_LICENSE', entityName: 'IRDA License - LI001234', expiry: daysFromNow(365), status: 'VALID', notes: 'General insurance license' },
    { type: 'ARN', entityName: 'ARN-67890 (Branch Delhi)', expiry: daysFromNow(25), status: 'EXPIRING_SOON', notes: 'Branch ARN renewal pending' },
    { type: 'EUIN', entityName: 'Staff EUIN (E567802)', expiry: daysFromNow(18), status: 'EXPIRING_SOON', notes: 'EUIN expiring, NISM exam scheduled' },
    { type: 'KYC', entityName: 'Client C', expiry: daysFromNow(40), status: 'EXPIRING_SOON', notes: 'KYC renewal documents requested' },
    { type: 'INSURANCE_LICENSE', entityName: 'IRDA License - LI005678', expiry: daysFromNow(30), status: 'EXPIRING_SOON', notes: 'Life insurance license renewal pending' },
    { type: 'EUIN', entityName: 'Old RM EUIN (E999903)', expiry: daysAgo(15), status: 'EXPIRED', notes: 'Former RM, EUIN expired' },
    { type: 'KYC', entityName: 'Client D', expiry: daysAgo(30), status: 'EXPIRED', notes: 'KYC expired, transactions blocked until renewal' },
  ];

  for (const c of complianceEntries) {
    await prisma.complianceRecord.create({
      data: {
        advisorId,
        type: c.type as any,
        entityName: c.entityName,
        expiryDate: c.expiry,
        status: c.status as any,
        notes: c.notes,
      },
    });
  }
  console.log(`    ✓ ${complianceEntries.length} compliance records`);

  // ═══════════════════════════════════════════
  // 11. AUDIT LOGS
  // ═══════════════════════════════════════════
  console.log('  📜 Creating audit trail...');

  const auditActions = [
    { action: 'LOGIN', entityType: 'User', details: 'Advisor login from Mumbai' },
    { action: 'CREATE_CLIENT', entityType: 'FAClient', details: 'New client onboarded' },
    { action: 'UPDATE_CLIENT', entityType: 'FAClient', details: 'Updated client risk profile' },
    { action: 'CREATE_SIP', entityType: 'FASIP', details: 'New SIP created for 25000/month' },
    { action: 'CREATE_TRANSACTION', entityType: 'FATransaction', details: 'Lumpsum purchase of 500000' },
    { action: 'ASSIGN_RM', entityType: 'FAClient', details: 'Assigned RM to client' },
    { action: 'CREATE_BRANCH', entityType: 'Branch', details: 'New branch office added' },
    { action: 'CREATE_COMPLIANCE_RECORD', entityType: 'ComplianceRecord', details: 'ARN renewal tracked' },
    { action: 'UPLOAD_BROKERAGE', entityType: 'BrokerageUpload', details: 'CAMS CSV uploaded' },
    { action: 'RECONCILE_COMMISSIONS', entityType: 'CommissionRecord', details: 'Monthly reconciliation completed' },
    { action: 'CREATE_CRM_TASK', entityType: 'CRMTask', details: 'Follow-up task assigned' },
    { action: 'COMPLETE_CRM_TASK', entityType: 'CRMTask', details: 'SIP registration task completed' },
    { action: 'LOGIN', entityType: 'User', details: 'Staff login from branch' },
    { action: 'UPDATE_COMMISSION_RATE', entityType: 'CommissionRateMaster', details: 'Updated trail rate for HDFC Equity' },
    { action: 'CALCULATE_EXPECTED_COMMISSIONS', entityType: 'CommissionRecord', details: 'Calculated expected for Jan 2026' },
  ];

  for (let i = 0; i < auditActions.length; i++) {
    const a = auditActions[i];
    await prisma.auditLog.create({
      data: {
        userId: i < 10 ? advisorId : (existingStaff.length > 0 ? existingStaff[0].staffUserId : advisorId),
        action: a.action,
        entityType: a.entityType,
        entityId: clients.length > 0 ? clients[i % clients.length].id : null,
        newValue: a.details,
        ipAddress: pick(['192.168.1.10', '10.0.0.5', '172.16.0.1', '103.25.200.50']),
        createdAt: daysAgo(Math.floor(Math.random() * 30)),
      },
    });
  }
  console.log(`    ✓ ${auditActions.length} audit logs`);

  return {
    branches: branches.length,
    rateCount,
    recordCount,
    uploads: uploadData.length,
    snapshots: snapshotCount,
    tasks: taskCount,
    activities: activityCount,
    compliance: complianceEntries.length,
    audits: auditActions.length,
  };
}

// =============================================
// MAIN SEED FUNCTION
// =============================================

async function main() {
  console.log('🏢 Phase 2: Seeding Business Management data...\n');

  // ── Look up existing advisors ──
  const advisors = await prisma.user.findMany({
    where: { role: 'advisor', email: { notIn: ['self-service@sparrowinvest.com', 'self-service@sparrow-invest.com'] } },
  });

  if (advisors.length === 0) {
    console.log('❌ No advisors found. Run the main seed first: npm run db:seed');
    return;
  }

  console.log(`Found ${advisors.length} advisors: ${advisors.map(a => a.email).join(', ')}\n`);

  // ── Seed FULL data for primary advisors ──
  // Match both @sparrowinvest.com and @sparrow-invest.com formats
  const primaryPatterns = [
    { match: (e: string) => e.startsWith('advisor@') && !e.includes('test'), prefix: 'Main' },
    { match: (e: string) => e.startsWith('priya.sharma@'), prefix: 'PS' },
  ];

  const seededIds = new Set<string>();
  for (const pat of primaryPatterns) {
    const advisor = advisors.find(a => pat.match(a.email));
    if (!advisor) {
      console.log(`⚠️  No advisor matching pattern found, skipping`);
      continue;
    }
    seededIds.add(advisor.id);
    const stats = await seedForAdvisor(advisor.id, advisor.email, pat.prefix);
    console.log(`\n  📊 Summary: ${stats.branches} branches, ${stats.rateCount} rates, ${stats.recordCount} commission records, ${stats.uploads} uploads, ${stats.snapshots} AUM snapshots, ${stats.tasks} CRM tasks, ${stats.activities} activities, ${stats.compliance} compliance, ${stats.audits} audit logs`);
  }

  // ── Seed smaller set for remaining advisors ──
  const otherAdvisors = advisors.filter(a => !seededIds.has(a.id) && !a.email.includes('test')).slice(0, 3);

  if (otherAdvisors.length > 0) {
    console.log('\n\n🔄 Seeding smaller data sets for other advisors...');

    for (const advisor of otherAdvisors) {
      const prefix = advisor.email.split('@')[0].slice(0, 4).toUpperCase();

      // 2 branches
      await prisma.branch.create({
        data: { advisorId: advisor.id, name: `${prefix} - Main Office`, city: 'Mumbai', code: `${prefix}-MAIN` },
      });
      await prisma.branch.create({
        data: { advisorId: advisor.id, name: `${prefix} - Branch 2`, city: 'Delhi', code: `${prefix}-BR2` },
      });

      // 3 compliance records
      for (const c of [
        { type: 'ARN', entityName: `ARN - ${advisor.email.split('@')[0]}`, expiry: daysFromNow(300), status: 'VALID' },
        { type: 'EUIN', entityName: 'EUIN - Staff', expiry: daysFromNow(45), status: 'EXPIRING_SOON' },
        { type: 'KYC', entityName: 'Client KYC', expiry: daysAgo(10), status: 'EXPIRED' },
      ]) {
        await prisma.complianceRecord.create({
          data: {
            advisorId: advisor.id,
            type: c.type as any,
            entityName: c.entityName,
            expiryDate: c.expiry,
            status: c.status as any,
          },
        });
      }

      // AUM snapshots (last 30 days)
      const otherBaseAum = randomBetween(5000000, 20000000);
      for (let d = 30; d >= 0; d -= 3) {
        const date = daysAgo(d);
        if (date.getDay() === 0 || date.getDay() === 6) continue;

        const totalAum = otherBaseAum * (1 + ((30 - d) / 30) * 0.03) * (1 + (Math.random() - 0.5) * 0.01);
        await prisma.aUMSnapshot.upsert({
          where: { advisorId_date: { advisorId: advisor.id, date } },
          update: {},
          create: {
            advisorId: advisor.id,
            date,
            totalAum: Math.round(totalAum),
            equityAum: Math.round(totalAum * 0.6),
            debtAum: Math.round(totalAum * 0.25),
            hybridAum: Math.round(totalAum * 0.15),
            clientCount: Math.floor(Math.random() * 10) + 5,
            sipBookSize: Math.round(randomBetween(50000, 200000)),
            netFlows: Math.round(randomBetween(-100000, 300000)),
          },
        });
      }

      console.log(`  ✓ Seeded data for ${advisor.email}`);
    }
  }

  // ═══════════════════════════════════════════
  // SUMMARY
  // ═══════════════════════════════════════════
  console.log('\n═══════════════════════════════════════════');
  console.log('✅ Phase 2 Business Management seed complete!');
  console.log('═══════════════════════════════════════════');
  console.log('\n🔑 Login with any advisor account:');
  console.log('   advisor@sparrowinvest.com / Advisor@123 (full data)');
  console.log('   priya.sharma@sparrowinvest.com / Advisor@123 (full data)');
  console.log('');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
