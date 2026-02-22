import { PrismaClient } from '@prisma/client';

/**
 * One-time setup: pg_trgm extension + GIN index on scheme_plans.name
 * Enables sub-ms ILIKE pattern matching for fund name search.
 *
 * Run after `npx prisma db push`:
 *   npx ts-node prisma/setup-trgm-index.ts
 */

const prisma = new PrismaClient();

async function main() {
  console.log('Creating pg_trgm extension...');
  await prisma.$executeRaw`CREATE EXTENSION IF NOT EXISTS pg_trgm`;

  console.log('Creating GIN trigram index on scheme_plans.name...');
  await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_scheme_plans_name_trgm ON scheme_plans USING gin (name gin_trgm_ops)`;

  console.log('Done. PostgreSQL will automatically use the GIN index for ILIKE queries.');
}

main()
  .catch(e => {
    console.error('Failed:', e.message);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
