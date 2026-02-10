# Production Deployment Guide - Sparrow Invest

> **Status**: Pre-deployment checklist and architectural improvements
> **Last Updated**: January 2026
> **Priority Legend**: 🔴 Critical | 🟡 High | 🟢 Medium

---

## Table of Contents

1. [Pre-Deployment Checklist](#1-pre-deployment-checklist)
2. [Security Fixes (Required)](#2-security-fixes-required)
3. [Database Optimizations](#3-database-optimizations)
4. [Backend Improvements](#4-backend-improvements)
5. [Frontend Improvements](#5-frontend-improvements)
6. [ML Service Improvements](#6-ml-service-improvements)
7. [Infrastructure Setup](#7-infrastructure-setup)
8. [CI/CD Pipeline](#8-cicd-pipeline)
9. [Monitoring & Observability](#9-monitoring--observability)
10. [Deployment Timeline](#10-deployment-timeline)

---

## 1. Pre-Deployment Checklist

### Security
- [ ] Remove JWT secret fallback value
- [ ] Add rate limiting to all endpoints
- [ ] Move CORS origins to environment variables
- [ ] Add password complexity validation
- [ ] Remove development mode role bypass
- [ ] Enable HTTPS enforcement
- [ ] Add API key auth for public ML endpoints

### Database
- [ ] Add missing indexes (User.email, Order, FATransaction, Folio, Holding)
- [ ] Fix Float → Decimal in UserProfile
- [ ] Add check constraints for numeric ranges
- [ ] Set up migration strategy (switch from db push to migrate)
- [ ] Plan table partitioning for time-series data

### Infrastructure
- [ ] Set up CI/CD pipelines
- [ ] Configure production Docker images
- [ ] Set up load balancer
- [ ] Configure CDN for static assets
- [ ] Set up database backups
- [ ] Configure Redis for production
- [ ] Set up monitoring stack

---

## 2. Security Fixes (Required)

### 2.1 JWT Secret - Remove Default Fallback 🔴

**File**: `backend/src/config/configuration.ts`

```typescript
// BEFORE (vulnerable)
jwt: {
  secret: process.env.JWT_SECRET || 'super-secret',
  expiresIn: process.env.JWT_EXPIRES_IN || '7d',
}

// AFTER (secure)
jwt: {
  secret: process.env.JWT_SECRET, // Will throw if missing
  expiresIn: process.env.JWT_EXPIRES_IN || '7d',
}
```

Add validation in `main.ts`:
```typescript
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required');
}
```

### 2.2 Rate Limiting 🔴

**Install**: `npm install @nestjs/throttler`

**File**: `backend/src/app.module.ts`

```typescript
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000,    // 1 second
        limit: 3,     // 3 requests per second
      },
      {
        name: 'medium',
        ttl: 10000,   // 10 seconds
        limit: 20,    // 20 requests per 10 seconds
      },
      {
        name: 'long',
        ttl: 60000,   // 1 minute
        limit: 100,   // 100 requests per minute
      },
    ]),
    // ... other imports
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
```

### 2.3 CORS Configuration 🟡

**File**: `backend/src/main.ts`

```typescript
// BEFORE (hardcoded)
app.enableCors({
  origin: [
    'http://localhost:3500',
    'http://localhost:3502',
  ],
  credentials: true,
});

// AFTER (environment-driven)
const corsOrigins = process.env.CORS_ORIGINS?.split(',') || [];
if (corsOrigins.length === 0 && process.env.NODE_ENV === 'production') {
  throw new Error('CORS_ORIGINS must be set in production');
}

app.enableCors({
  origin: process.env.NODE_ENV === 'production'
    ? corsOrigins
    : true, // Allow all in development
  credentials: true,
});
```

**Environment variable**:
```env
CORS_ORIGINS=https://app.sparrowinvest.com,https://admin.sparrowinvest.com
```

### 2.4 Remove Development Role Bypass 🔴

**File**: `backend/src/common/guards/roles.guard.ts`

```typescript
// REMOVE these lines (14-18):
const nodeEnv = this.configService.get<string>('nodeEnv');
if (nodeEnv === 'development') {
  return true;
}
```

### 2.5 Password Complexity 🟡

**File**: `backend/src/auth/dto/register.dto.ts`

```typescript
import { Matches, MinLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(8)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/,
    {
      message: 'Password must contain uppercase, lowercase, number, and special character',
    }
  )
  password: string;
}
```

### 2.6 Security Headers 🟡

**Install**: `npm install helmet`

**File**: `backend/src/main.ts`

```typescript
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security headers
  app.use(helmet());

  // ... rest of config
}
```

---

## 3. Database Optimizations

### 3.1 Critical Missing Indexes 🔴

Add to `backend/prisma/schema.prisma`:

```prisma
model User {
  // ... existing fields

  @@index([email])           // Auth queries
  @@index([isActive])        // User filtering
  @@index([role])            // Role-based queries
  @@index([createdAt])       // Time-based filtering
}

model Order {
  // ... existing fields

  @@index([createdAt])
  @@index([userId, createdAt])     // User's order history
  @@index([orderState, createdAt]) // State-based filtering
}

model FATransaction {
  // ... existing fields

  @@index([clientId, date(sort: Desc)])  // Transaction history
  @@index([type, status])                 // Type + status filtering
}

model Folio {
  // ... existing fields

  @@index([panNumber])            // PAN lookups
  @@index([userId, providerId])   // User-provider pairs
}

model Holding {
  // ... existing fields

  @@index([folioId])         // Folio's holdings
  @@index([schemePlanId])    // Fund analytics
}

model FAHolding {
  // ... existing fields

  @@index([schemePlanId])              // Fund analytics
  @@index([clientId, folioNumber])     // Folio composition
}

model UserProfile {
  // ... existing fields

  @@index([assignedPersonaId])   // Persona assignments
}

model Category {
  // ... existing fields

  @@index([parentId])   // Hierarchy traversal
}

model ApiLog {
  // ... existing fields

  @@index([userId])     // User activity
  @@index([endpoint])   // Endpoint analytics
}

model PersonaAnalytics {
  // ... existing fields

  @@index([date])              // Time-series queries
  @@index([personaId, date])   // Persona trends
}
```

### 3.2 Data Type Fixes 🔴

```prisma
// Fix Float to Decimal in UserProfile
model UserProfile {
  // Change these fields:
  targetAmount    Decimal? @db.Decimal(14, 2)  // Was Float
  monthlySip      Decimal? @db.Decimal(14, 2)  // Was Float
  lumpSum         Decimal? @db.Decimal(14, 2)  // Was Float
}

model UserPortfolioSnapshot {
  totalValue      Decimal? @db.Decimal(14, 2)  // Was Float
}

model AllocationComponent {
  allocationPercent Decimal @db.Decimal(5, 2)  // Was Float
}

model RiskConstraint {
  constraintValue Decimal @db.Decimal(10, 4)   // Was Float
}
```

### 3.3 Migration Strategy 🟡

Switch from `db push` to `prisma migrate`:

```bash
# Initialize migration history
npx prisma migrate dev --name init

# For future changes
npx prisma migrate dev --name add_indexes

# For production deployment
npx prisma migrate deploy
```

### 3.4 Table Partitioning (Future) 🟢

For time-series tables after 1 year of data:

```sql
-- Partition ApiLog by month
CREATE TABLE api_logs_partitioned (
  LIKE api_logs INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE api_logs_2026_01 PARTITION OF api_logs_partitioned
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

---

## 4. Backend Improvements

### 4.1 Add Redis Caching Layer 🟡

**Install**: `npm install @nestjs/cache-manager cache-manager cache-manager-redis-store`

**File**: `backend/src/app.module.ts`

```typescript
import { CacheModule } from '@nestjs/cache-manager';
import { redisStore } from 'cache-manager-redis-store';

@Module({
  imports: [
    CacheModule.registerAsync({
      isGlobal: true,
      useFactory: async () => ({
        store: await redisStore({
          socket: {
            host: process.env.REDIS_HOST,
            port: parseInt(process.env.REDIS_PORT || '6379'),
          },
        }),
        ttl: 300, // 5 minutes default
      }),
    }),
  ],
})
```

**Usage in services**:
```typescript
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';

@Injectable()
export class FundsService {
  constructor(@Inject(CACHE_MANAGER) private cache: Cache) {}

  async getPopularFunds() {
    const cacheKey = 'popular-funds';
    const cached = await this.cache.get(cacheKey);
    if (cached) return cached;

    const funds = await this.prisma.schemePlan.findMany({ /* ... */ });
    await this.cache.set(cacheKey, funds, 600); // 10 minutes
    return funds;
  }
}
```

### 4.2 Structured Logging 🟡

**Install**: `npm install winston nest-winston`

**File**: `backend/src/main.ts`

```typescript
import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';

const app = await NestFactory.create(AppModule, {
  logger: WinstonModule.createLogger({
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.timestamp(),
          winston.format.json(),
        ),
      }),
    ],
  }),
});
```

### 4.3 Health Checks 🟡

**Install**: `npm install @nestjs/terminus`

**File**: `backend/src/health/health.controller.ts`

```typescript
import { Controller, Get } from '@nestjs/common';
import { HealthCheck, HealthCheckService, PrismaHealthIndicator } from '@nestjs/terminus';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private prisma: PrismaHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.prisma.pingCheck('database'),
      // Add Redis, ML service checks
    ]);
  }
}
```

### 4.4 Error Tracking (Sentry) 🟢

**Install**: `npm install @sentry/node`

**File**: `backend/src/main.ts`

```typescript
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
});
```

---

## 5. Frontend Improvements

### 5.1 Add Data Fetching Layer (SWR) 🟡

**Install**: `npm install swr`

**File**: `platforms/web/src/hooks/useClients.ts`

```typescript
import useSWR from 'swr';
import { clientsApi, ClientFilters } from '@/services/api';

export function useClients(filters: ClientFilters) {
  const { data, error, isLoading, mutate } = useSWR(
    ['clients', filters],
    () => clientsApi.getAll(filters),
    {
      revalidateOnFocus: false,
      dedupingInterval: 30000,
    }
  );

  return {
    clients: data?.data || [],
    pagination: data?.pagination,
    isLoading,
    isError: error,
    refresh: mutate,
  };
}
```

### 5.2 Global Error Boundary 🟡

**File**: `platforms/web/src/components/ErrorBoundary.tsx`

```typescript
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error:', error, errorInfo);
    // Send to Sentry
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="p-8 text-center">
          <h2>Something went wrong</h2>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
```

### 5.3 Token Refresh Mechanism 🟢

**File**: `platforms/web/src/context/AuthContext.tsx`

```typescript
// Add token refresh logic
useEffect(() => {
  const token = getAuthToken();
  if (!token) return;

  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    const expiresAt = payload.exp * 1000;
    const refreshThreshold = 5 * 60 * 1000; // 5 minutes before expiry

    if (expiresAt - Date.now() < refreshThreshold) {
      // Token about to expire, refresh it
      refreshToken();
    }
  } catch {
    clearAuthToken();
  }
}, []);
```

---

## 6. ML Service Improvements

### 6.1 Add Prometheus Metrics 🟡

**Install**: `pip install prometheus-fastapi-instrumentator`

**File**: `ml-service/app/main.py`

```python
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

# Add Prometheus metrics
Instrumentator().instrument(app).expose(app)
```

### 6.2 Add Tests 🟡

**File**: `ml-service/tests/test_persona_service.py`

```python
import pytest
from app.services.persona_service import PersonaService

@pytest.fixture
def persona_service():
    return PersonaService()

def test_classify_conservative_profile(persona_service):
    profile = {
        "age": 55,
        "risk_tolerance": "low",
        "investment_horizon": 3,
        "liquidity_needs": "high",
    }
    result = persona_service.classify(profile)
    assert result["persona"] == "Capital Guardian"
    assert result["confidence"] >= 0.7
```

### 6.3 Model Versioning 🟢

**File**: `ml-service/app/services/model_manager.py`

```python
import joblib
from pathlib import Path
from datetime import datetime

class ModelManager:
    def __init__(self, models_dir: str = "./models_store"):
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(exist_ok=True)

    def save_model(self, model, name: str, version: str = None):
        version = version or datetime.now().strftime("%Y%m%d_%H%M%S")
        path = self.models_dir / f"{name}_v{version}.joblib"
        joblib.dump(model, path)
        return str(path)

    def load_model(self, name: str, version: str = "latest"):
        if version == "latest":
            files = list(self.models_dir.glob(f"{name}_v*.joblib"))
            if not files:
                return None
            path = max(files, key=lambda p: p.stat().st_mtime)
        else:
            path = self.models_dir / f"{name}_v{version}.joblib"
        return joblib.load(path) if path.exists() else None
```

---

## 7. Infrastructure Setup

### 7.1 Production Docker Compose 🟡

**File**: `docker-compose.prod.yml`

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@sparrowinvest.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - letsencrypt:/letsencrypt
    networks:
      - web

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - JWT_SECRET=${JWT_SECRET}
      - REDIS_HOST=redis
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=Host(`api.sparrowinvest.com`)"
      - "traefik.http.routers.backend.tls.certresolver=letsencrypt"
    depends_on:
      - postgres
      - redis
    networks:
      - web
      - internal

  ml-service:
    build:
      context: ./ml-service
      dockerfile: Dockerfile
    environment:
      - ENVIRONMENT=production
      - BACKEND_URL=http://backend:3501
      - REDIS_HOST=redis
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ml.rule=Host(`ml.sparrowinvest.com`)"
      - "traefik.http.routers.ml.tls.certresolver=letsencrypt"
    depends_on:
      - redis
    networks:
      - web
      - internal

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=sparrowinvest
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - internal

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - internal

volumes:
  postgres_data:
  redis_data:
  letsencrypt:

networks:
  web:
    external: true
  internal:
```

### 7.2 Production Environment Variables 🔴

**File**: `.env.production` (template)

```env
# Database
DATABASE_URL=postgresql://user:password@postgres:5432/sparrowinvest
POSTGRES_USER=sparrowinvest
POSTGRES_PASSWORD=<generate-strong-password>

# Authentication
JWT_SECRET=<generate-256-bit-secret>
JWT_EXPIRES_IN=7d

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# CORS
CORS_ORIGINS=https://app.sparrowinvest.com,https://admin.sparrowinvest.com

# ML Service
ML_SERVICE_URL=ml-service:3503
ML_SERVICE_HTTP_URL=http://ml-service:8000

# Monitoring
SENTRY_DSN=<your-sentry-dsn>

# MinIO (if using)
MINIO_ENDPOINT=minio
MINIO_PORT=9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=sparrowinvest
```

---

## 8. CI/CD Pipeline

### 8.1 GitHub Actions - Backend 🟡

**File**: `.github/workflows/backend.yml`

```yaml
name: Backend CI/CD

on:
  push:
    branches: [main]
    paths: ['backend/**']
  pull_request:
    branches: [main]
    paths: ['backend/**']

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_DB: test
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - name: Install dependencies
        run: cd backend && npm ci

      - name: Run tests
        run: cd backend && npm test
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
          JWT_SECRET: test-secret

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: |
          docker build -t ghcr.io/${{ github.repository }}/backend:${{ github.sha }} ./backend
          docker tag ghcr.io/${{ github.repository }}/backend:${{ github.sha }} ghcr.io/${{ github.repository }}/backend:latest

      - name: Push to registry
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
          docker push ghcr.io/${{ github.repository }}/backend:latest
```

### 8.2 GitHub Actions - ML Service 🟡

**File**: `.github/workflows/ml-service.yml`

```yaml
name: ML Service CI/CD

on:
  push:
    branches: [main]
    paths: ['ml-service/**']
  pull_request:
    branches: [main]
    paths: ['ml-service/**']

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'
          cache-dependency-path: ml-service/requirements.txt

      - name: Install dependencies
        run: |
          cd ml-service
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run tests
        run: cd ml-service && pytest --cov=app tests/

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: |
          docker build -t ghcr.io/${{ github.repository }}/ml-service:${{ github.sha }} ./ml-service

      - name: Push to registry
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/${{ github.repository }}/ml-service:${{ github.sha }}
```

### 8.3 GitHub Actions - Frontend 🟡

**File**: `.github/workflows/frontend.yml`

```yaml
name: Frontend CI/CD

on:
  push:
    branches: [main]
    paths: ['platforms/web/**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: platforms/web/package-lock.json

      - name: Install dependencies
        run: cd platforms/web && npm ci

      - name: Build
        run: cd platforms/web && npm run build
        env:
          NEXT_PUBLIC_API_URL: https://api.sparrowinvest.com

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
          working-directory: ./platforms/web
```

---

## 9. Monitoring & Observability

### 9.1 Prometheus + Grafana Stack 🟢

**File**: `monitoring/docker-compose.yml`

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3000:3000"
    depends_on:
      - prometheus

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki_data:/loki

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
```

**File**: `monitoring/prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'backend'
    static_configs:
      - targets: ['backend:3501']
    metrics_path: '/metrics'

  - job_name: 'ml-service'
    static_configs:
      - targets: ['ml-service:8000']
    metrics_path: '/metrics'

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

### 9.2 Key Metrics to Monitor 🟢

| Metric | Source | Alert Threshold |
|--------|--------|-----------------|
| API Response Time (p95) | Backend | > 500ms |
| API Error Rate | Backend | > 1% |
| Database Connections | PostgreSQL | > 80% pool |
| Redis Memory | Redis | > 80% max |
| ML Inference Latency | ML Service | > 2s |
| JWT Auth Failures | Backend | > 10/min |
| SIP Processing Errors | Backend | > 0/hour |

---

## 10. Deployment Timeline

### Week 1-2: Security & Critical Fixes

| Day | Task | Owner |
|-----|------|-------|
| 1 | Remove JWT secret fallback | Backend |
| 1 | Add rate limiting | Backend |
| 2 | Add password complexity validation | Backend |
| 2 | Move CORS to env vars | Backend |
| 3 | Add critical database indexes | Database |
| 3 | Fix Float → Decimal types | Database |
| 4 | Set up CI/CD pipelines | DevOps |
| 5 | Security review & penetration testing | Security |

### Week 3-4: Infrastructure & Monitoring

| Day | Task | Owner |
|-----|------|-------|
| 1 | Set up production Docker images | DevOps |
| 2 | Configure Traefik + SSL | DevOps |
| 3 | Set up Prometheus + Grafana | DevOps |
| 4 | Add health checks to all services | Backend/ML |
| 5 | Add structured logging | Backend/ML |
| 6 | Set up Sentry error tracking | All |
| 7 | Add Redis caching layer | Backend |

### Week 5-6: Testing & Staging

| Day | Task | Owner |
|-----|------|-------|
| 1-2 | Deploy to staging environment | DevOps |
| 3-4 | Load testing (k6/Locust) | QA |
| 5 | Performance optimization | All |
| 6 | Security scan (OWASP ZAP) | Security |
| 7 | UAT with stakeholders | Product |

### Week 7: Production Deployment

| Day | Task | Owner |
|-----|------|-------|
| 1 | Final security review | Security |
| 2 | Database migration to production | Database |
| 3 | Deploy backend + ML service | DevOps |
| 4 | Deploy frontend to Vercel/CDN | DevOps |
| 5 | Smoke testing + monitoring | All |
| 6-7 | Hypercare period | All |

---

## Appendix: Quick Commands

### Database

```bash
# Run migrations
cd backend && npx prisma migrate deploy

# Seed production data (if needed)
cd backend && npx ts-node prisma/seed.ts

# Generate Prisma client
cd backend && npx prisma generate
```

### Docker

```bash
# Build all services
docker-compose -f docker-compose.prod.yml build

# Start production stack
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f backend ml-service

# Scale services
docker-compose -f docker-compose.prod.yml up -d --scale backend=3
```

### Backup

```bash
# Backup database
docker exec postgres pg_dump -U sparrowinvest sparrowinvest > backup_$(date +%Y%m%d).sql

# Restore database
docker exec -i postgres psql -U sparrowinvest sparrowinvest < backup_20260128.sql
```

---

**Document Version**: 1.0
**Next Review**: Before production deployment
