# Database Schema Changes - TODO

> Created: 2026-01-31
> Last Updated: 2026-01-31
> Status: **P0 + P1 + P2 + P3 Complete** (Core APIs Done)

---

## Implementation Progress

| Priority | Description | Status |
|----------|-------------|--------|
| **P0** | Goals, Portfolio History | ✅ **Complete** |
| **P1** | Market Indices, Dividends, Points | ✅ **Complete** |
| **P2** | Tax, Advisors | ✅ **Complete** |
| **P3** | User Actions | ✅ **Complete** |
| **P2** | Broker Connections | 🔜 Deferred (requires OAuth) |
| **P3** | AI Chat | 🔜 Deferred (requires AI integration) |

---

## Summary

Based on iOS app mock data audit, the following database schema changes are required to replace hardcoded/mock data with real API data.

---

## iOS Mock Data Audit Results

| Store/File | Mock Data | Status |
|------------|-----------|--------|
| **PortfolioStore** | Holdings, SIPs, Transactions, Asset Allocation | Uses fallback mock |
| **FundsStore** | Fund catalog (5 funds), NAVs, Returns, Recommendations | Uses fallback mock |
| **GoalsStore** | 3 sample goals with targets/progress | ✅ API exists, mock fallback |
| **DashboardStore** | Market indices, Portfolio history, Tax summary, Dividends, Actions | ✅ API exists, mock fallback |
| **FamilyStore** | Family member portfolios, 12-month history | ✅ API exists, mock fallback |
| **PointsStore** | Points balance, transaction history | ✅ API exists, mock fallback |
| **AdvisorStore** | Advisor list with ratings | ✅ API exists, mock fallback |
| **ProfileView** | Membership tier, family members, connected accounts | **Hardcoded in UI** |
| **AIChatView** | 8 dummy AI responses | **Hardcoded responses** (AI deferred) |

---

## New Tables Required

### Priority 0 (Critical)

#### 1. UserGoal & GoalContribution
```prisma
enum GoalCategory {
  HOME
  RETIREMENT
  EDUCATION
  EMERGENCY
  WEDDING
  TRAVEL
  CAR
  WEALTH
  CUSTOM
}

enum GoalStatus {
  ACTIVE
  COMPLETED
  PAUSED
  CANCELLED
}

model UserGoal {
  id              String       @id @default(uuid())
  userId          String       @map("user_id")
  clientId        String?      @map("client_id")  // For FA clients
  name            String
  category        GoalCategory
  icon            String?                         // SF Symbol name
  targetAmount    Decimal      @map("target_amount") @db.Decimal(14, 2)
  currentAmount   Decimal      @default(0) @map("current_amount") @db.Decimal(14, 2)
  targetDate      DateTime     @map("target_date") @db.Date
  monthlySip      Decimal?     @map("monthly_sip") @db.Decimal(14, 2)
  status          GoalStatus   @default(ACTIVE)
  priority        Int          @default(1)        // 1-5
  linkedFundCodes String[]     @map("linked_fund_codes")
  notes           String?
  createdAt       DateTime     @default(now()) @map("created_at")
  updatedAt       DateTime     @updatedAt @map("updated_at")

  user          User               @relation(fields: [userId], references: [id], onDelete: Cascade)
  client        FAClient?          @relation(fields: [clientId], references: [id])
  contributions GoalContribution[]

  @@index([userId])
  @@index([clientId])
  @@index([status])
  @@map("user_goals")
}

model GoalContribution {
  id          String   @id @default(uuid())
  goalId      String   @map("goal_id")
  amount      Decimal  @db.Decimal(14, 2)
  type        String                      // SIP, LUMPSUM, RETURNS, DIVIDEND
  date        DateTime @db.Date
  description String?
  createdAt   DateTime @default(now()) @map("created_at")

  goal UserGoal @relation(fields: [goalId], references: [id], onDelete: Cascade)

  @@index([goalId])
  @@map("goal_contributions")
}
```

#### 2. UserPortfolioHistory
```prisma
model UserPortfolioHistory {
  id             Int      @id @default(autoincrement())
  userId         String   @map("user_id")
  clientId       String?  @map("client_id")    // For FA clients
  date           DateTime @db.Date
  totalValue     Decimal  @map("total_value") @db.Decimal(14, 2)
  totalInvested  Decimal  @map("total_invested") @db.Decimal(14, 2)
  dayChange      Decimal? @map("day_change") @db.Decimal(14, 2)
  dayChangePct   Decimal? @map("day_change_pct") @db.Decimal(8, 4)

  user   User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  client FAClient? @relation(fields: [clientId], references: [id])

  @@unique([userId, date])
  @@unique([clientId, date])
  @@index([userId, date(sort: Desc)])
  @@index([clientId, date(sort: Desc)])
  @@map("user_portfolio_history")
}
```

---

### Priority 1 (Important)

#### 3. MarketIndex & MarketIndexHistory
```prisma
model MarketIndex {
  id           String   @id @default(uuid())
  symbol       String   @unique           // NIFTY50, SENSEX, NIFTYBANK
  name         String                     // NIFTY 50, S&P BSE SENSEX
  currentValue Decimal  @map("current_value") @db.Decimal(14, 2)
  change       Decimal  @db.Decimal(10, 2)
  changePercent Decimal @map("change_pct") @db.Decimal(8, 4)
  previousClose Decimal @map("previous_close") @db.Decimal(14, 2)
  dayHigh      Decimal? @map("day_high") @db.Decimal(14, 2)
  dayLow       Decimal? @map("day_low") @db.Decimal(14, 2)
  lastUpdated  DateTime @map("last_updated")
  isActive     Boolean  @default(true) @map("is_active")

  history MarketIndexHistory[]

  @@map("market_indices")
}

model MarketIndexHistory {
  id        Int      @id @default(autoincrement())
  indexId   String   @map("index_id")
  date      DateTime @db.Date
  open      Decimal  @db.Decimal(14, 2)
  high      Decimal  @db.Decimal(14, 2)
  low       Decimal  @db.Decimal(14, 2)
  close     Decimal  @db.Decimal(14, 2)
  volume    BigInt?

  index MarketIndex @relation(fields: [indexId], references: [id], onDelete: Cascade)

  @@unique([indexId, date])
  @@index([indexId, date(sort: Desc)])
  @@map("market_index_history")
}
```

#### 4. DividendRecord
```prisma
model DividendRecord {
  id             String   @id @default(uuid())
  userId         String   @map("user_id")
  clientId       String?  @map("client_id")
  fundName       String   @map("fund_name")
  fundSchemeCode String   @map("fund_scheme_code")
  amount         Decimal  @db.Decimal(14, 2)
  dividendType   String   @map("dividend_type")  // PAYOUT, REINVESTED
  recordDate     DateTime @map("record_date") @db.Date
  paymentDate    DateTime @map("payment_date") @db.Date
  nav            Decimal? @db.Decimal(14, 4)
  units          Decimal? @db.Decimal(14, 4)     // If reinvested
  createdAt      DateTime @default(now()) @map("created_at")

  user   User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  client FAClient? @relation(fields: [clientId], references: [id])

  @@index([userId])
  @@index([clientId])
  @@index([paymentDate])
  @@map("dividend_records")
}
```

#### 5. UserPoints & PointsTransaction
```prisma
enum PointsTier {
  BRONZE
  SILVER
  GOLD
  PLATINUM
}

enum PointsTransactionType {
  EARNED_SIP
  EARNED_LUMPSUM
  EARNED_REFERRAL
  EARNED_KYC
  EARNED_GOAL
  EARNED_STREAK
  REDEEMED
  EXPIRED
}

model UserPoints {
  id               String     @id @default(uuid())
  userId           String     @unique @map("user_id")
  currentPoints    Int        @default(0) @map("current_points")
  lifetimePoints   Int        @default(0) @map("lifetime_points")
  redeemedPoints   Int        @default(0) @map("redeemed_points")
  tier             PointsTier @default(BRONZE)
  tierUpdatedAt    DateTime?  @map("tier_updated_at")
  pointsToNextTier Int        @default(0) @map("points_to_next_tier")
  sipStreak        Int        @default(0) @map("sip_streak")      // Consecutive months
  createdAt        DateTime   @default(now()) @map("created_at")
  updatedAt        DateTime   @updatedAt @map("updated_at")

  user         User                @relation(fields: [userId], references: [id], onDelete: Cascade)
  transactions PointsTransaction[]

  @@map("user_points")
}

model PointsTransaction {
  id          String                 @id @default(uuid())
  userPointsId String                @map("user_points_id")
  type        PointsTransactionType
  points      Int                    // Positive for earned, negative for redeemed
  description String
  referenceId String?                @map("reference_id")  // Link to SIP/transaction/goal
  expiresAt   DateTime?              @map("expires_at")
  createdAt   DateTime               @default(now()) @map("created_at")

  userPoints UserPoints @relation(fields: [userPointsId], references: [id], onDelete: Cascade)

  @@index([userPointsId])
  @@index([createdAt])
  @@map("points_transactions")
}
```

---

### Priority 2 (Medium)

#### 6. UserTaxSummary & CapitalGainRecord
```prisma
enum GainType {
  LTCG     // Long Term (>1 year for equity, >3 years for debt)
  STCG     // Short Term
}

model UserTaxSummary {
  id                 String   @id @default(uuid())
  userId             String   @map("user_id")
  financialYear      String   @map("financial_year")  // "2024-25"
  ltcgRealized       Decimal  @default(0) @map("ltcg_realized") @db.Decimal(14, 2)
  stcgRealized       Decimal  @default(0) @map("stcg_realized") @db.Decimal(14, 2)
  ltcgUnrealized     Decimal  @default(0) @map("ltcg_unrealized") @db.Decimal(14, 2)
  stcgUnrealized     Decimal  @default(0) @map("stcg_unrealized") @db.Decimal(14, 2)
  elssInvested       Decimal  @default(0) @map("elss_invested") @db.Decimal(14, 2)
  dividendReceived   Decimal  @default(0) @map("dividend_received") @db.Decimal(14, 2)
  taxHarvestingDone  Decimal  @default(0) @map("tax_harvesting_done") @db.Decimal(14, 2)
  updatedAt          DateTime @updatedAt @map("updated_at")

  user         User                @relation(fields: [userId], references: [id], onDelete: Cascade)
  capitalGains CapitalGainRecord[]

  @@unique([userId, financialYear])
  @@map("user_tax_summaries")
}

model CapitalGainRecord {
  id             String   @id @default(uuid())
  taxSummaryId   String   @map("tax_summary_id")
  fundName       String   @map("fund_name")
  fundSchemeCode String   @map("fund_scheme_code")
  gainType       GainType @map("gain_type")
  purchaseDate   DateTime @map("purchase_date") @db.Date
  saleDate       DateTime @map("sale_date") @db.Date
  purchaseValue  Decimal  @map("purchase_value") @db.Decimal(14, 2)
  saleValue      Decimal  @map("sale_value") @db.Decimal(14, 2)
  gain           Decimal  @db.Decimal(14, 2)
  taxableGain    Decimal  @map("taxable_gain") @db.Decimal(14, 2)
  createdAt      DateTime @default(now()) @map("created_at")

  taxSummary UserTaxSummary @relation(fields: [taxSummaryId], references: [id], onDelete: Cascade)

  @@index([taxSummaryId])
  @@map("capital_gain_records")
}
```

#### 7. ConnectedBrokerAccount
```prisma
enum BrokerConnectionStatus {
  CONNECTED
  DISCONNECTED
  PENDING
  FAILED
}

model ConnectedBrokerAccount {
  id             String                 @id @default(uuid())
  userId         String                 @map("user_id")
  brokerName     String                 @map("broker_name")  // Zerodha, Groww, Kuvera, Coin
  brokerLogo     String?                @map("broker_logo")
  status         BrokerConnectionStatus @default(PENDING)
  accountId      String?                @map("account_id")   // Masked account identifier
  lastSyncAt     DateTime?              @map("last_sync_at")
  accessToken    String?                @map("access_token") // Encrypted
  refreshToken   String?                @map("refresh_token") // Encrypted
  tokenExpiresAt DateTime?              @map("token_expires_at")
  importedHoldings Boolean              @default(false) @map("imported_holdings")
  createdAt      DateTime               @default(now()) @map("created_at")
  updatedAt      DateTime               @updatedAt @map("updated_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, brokerName])
  @@map("connected_broker_accounts")
}
```

#### 8. AdvisorProfile & AdvisorReview
```prisma
model AdvisorProfile {
  id                String   @id @default(uuid())
  userId            String   @unique @map("user_id")
  displayName       String   @map("display_name")
  bio               String?
  specializations   String[]                       // ["Retirement", "Tax Planning", "ELSS"]
  experienceYears   Int      @map("experience_years")
  sebiRegNo         String?  @map("sebi_reg_no")
  arnNo             String?  @map("arn_no")
  rating            Decimal  @default(0) @db.Decimal(3, 2)  // 0.00 - 5.00
  totalReviews      Int      @default(0) @map("total_reviews")
  totalClients      Int      @default(0) @map("total_clients")
  aumManaged        Decimal  @default(0) @map("aum_managed") @db.Decimal(16, 2)
  isAcceptingNew    Boolean  @default(true) @map("is_accepting_new")
  minInvestment     Decimal? @map("min_investment") @db.Decimal(14, 2)
  feeStructure      String?  @map("fee_structure")  // "0.5% AUM", "₹500/month"
  avatarUrl         String?  @map("avatar_url")
  city              String?
  languages         String[]
  isVerified        Boolean  @default(false) @map("is_verified")
  createdAt         DateTime @default(now()) @map("created_at")
  updatedAt         DateTime @updatedAt @map("updated_at")

  user    User             @relation(fields: [userId], references: [id], onDelete: Cascade)
  reviews AdvisorReview[]

  @@map("advisor_profiles")
}

model AdvisorReview {
  id              String   @id @default(uuid())
  advisorProfileId String  @map("advisor_profile_id")
  reviewerId      String   @map("reviewer_id")
  rating          Int                              // 1-5
  comment         String?
  isAnonymous     Boolean  @default(false) @map("is_anonymous")
  createdAt       DateTime @default(now()) @map("created_at")

  advisorProfile AdvisorProfile @relation(fields: [advisorProfileId], references: [id], onDelete: Cascade)
  reviewer       User           @relation(fields: [reviewerId], references: [id])

  @@unique([advisorProfileId, reviewerId])
  @@map("advisor_reviews")
}
```

---

### Priority 3 (Nice to Have)

#### 9. AIChatSession & AIChatMessage
```prisma
model AIChatSession {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  title     String?                     // Auto-generated or user-set
  context   Json?                       // Portfolio snapshot for context
  isActive  Boolean  @default(true) @map("is_active")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  user     User             @relation(fields: [userId], references: [id], onDelete: Cascade)
  messages AIChatMessage[]

  @@index([userId])
  @@map("ai_chat_sessions")
}

model AIChatMessage {
  id         String   @id @default(uuid())
  sessionId  String   @map("session_id")
  role       String                     // "user" or "assistant"
  content    String
  metadata   Json?                      // Recommendations, fund links, etc.
  createdAt  DateTime @default(now()) @map("created_at")

  session AIChatSession @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  @@index([sessionId])
  @@map("ai_chat_messages")
}
```

#### 10. UserAction (Reminders/Notifications)
```prisma
enum ActionType {
  SIP_DUE
  SIP_FAILED
  REBALANCE_RECOMMENDED
  GOAL_REVIEW
  TAX_HARVESTING
  KYC_EXPIRY
  DIVIDEND_RECEIVED
  NAV_ALERT
  CUSTOM
}

enum ActionPriority {
  LOW
  MEDIUM
  HIGH
  URGENT
}

model UserAction {
  id          String         @id @default(uuid())
  userId      String         @map("user_id")
  type        ActionType
  priority    ActionPriority @default(MEDIUM)
  title       String
  description String?
  actionUrl   String?        @map("action_url")  // Deep link
  referenceId String?        @map("reference_id") // SIP ID, Goal ID, etc.
  dueDate     DateTime?      @map("due_date")
  isRead      Boolean        @default(false) @map("is_read")
  isDismissed Boolean        @default(false) @map("is_dismissed")
  isCompleted Boolean        @default(false) @map("is_completed")
  createdAt   DateTime       @default(now()) @map("created_at")
  expiresAt   DateTime?      @map("expires_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, isCompleted, isDismissed])
  @@index([dueDate])
  @@map("user_actions")
}
```

---

## Updates to Existing Models

Add these relations to the `User` model:

```prisma
model User {
  // ... existing fields ...

  // New relations
  goals              UserGoal[]
  points             UserPoints?
  portfolioHistory   UserPortfolioHistory[]
  taxSummaries       UserTaxSummary[]
  dividends          DividendRecord[]
  connectedAccounts  ConnectedBrokerAccount[]
  advisorProfile     AdvisorProfile?
  advisorReviews     AdvisorReview[]   @relation("ReviewerReviews")
  chatSessions       AIChatSession[]
  actions            UserAction[]
}
```

Add these relations to the `FAClient` model:

```prisma
model FAClient {
  // ... existing fields ...

  // New relations
  goals            UserGoal[]
  portfolioHistory UserPortfolioHistory[]
  dividends        DividendRecord[]
}
```

---

## API Endpoints to Implement

| Endpoint | Method | Priority | Status | Description |
|----------|--------|----------|--------|-------------|
| `/api/v1/me/goals` | GET, POST | P0 | ✅ Done | User goals CRUD |
| `/api/v1/me/goals/:id` | GET, PUT, DELETE | P0 | ✅ Done | Single goal operations |
| `/api/v1/me/goals/:id/contributions` | GET, POST | P0 | ✅ Done | Goal contributions |
| `/api/v1/auth/me/portfolio/history` | GET | P0 | ✅ Done | Portfolio history (30/90/365 days) |
| `/api/v1/market/indices` | GET | P1 | ✅ Done | Real-time market indices |
| `/api/v1/market/indices/:symbol` | GET | P1 | ✅ Done | Index history |
| `/api/v1/market/status` | GET | P1 | ✅ Done | Market open/closed status |
| `/api/v1/auth/me/dividends` | GET | P1 | ✅ Done | Dividend history |
| `/api/v1/me/points` | GET | P1 | ✅ Done | Points balance & tier |
| `/api/v1/me/points/transactions` | GET | P1 | ✅ Done | Points transaction history |
| `/api/v1/me/taxes/summary` | GET | P2 | ✅ Done | Tax summary for FY |
| `/api/v1/me/taxes/capital-gains` | GET | P2 | ✅ Done | Capital gains records |
| `/api/v1/me/connected-accounts` | GET, POST, DELETE | P2 | 🔜 Deferred | Brokerage connections (OAuth) |
| `/api/v1/advisors` | GET | P2 | ✅ Done | Advisor list with filters |
| `/api/v1/advisors/:id` | GET | P2 | ✅ Done | Advisor profile details |
| `/api/v1/advisors/:id/reviews` | GET, POST | P2 | ✅ Done | Advisor reviews |
| `/api/v1/advisors/specializations` | GET | P2 | ✅ Done | Available specializations |
| `/api/v1/ai/chat` | POST | P3 | 🔜 Deferred | AI chat endpoint (AI integration) |
| `/api/v1/ai/sessions` | GET, POST | P3 | 🔜 Deferred | Chat session management |
| `/api/v1/me/actions` | GET, POST | P3 | ✅ Done | Upcoming actions/reminders |
| `/api/v1/me/actions/:id` | GET, PUT | P3 | ✅ Done | Single action operations |
| `/api/v1/me/actions/:id/read` | PUT | P3 | ✅ Done | Mark action as read |
| `/api/v1/me/actions/:id/dismiss` | PUT | P3 | ✅ Done | Dismiss action |
| `/api/v1/me/actions/:id/complete` | PUT | P3 | ✅ Done | Complete action |

> **Note**: Routes changed from `/api/v1/users/*` to `/api/v1/me/*` to avoid collision with admin UsersController.

---

## Implementation Order

1. ✅ **Day 1**: Create Prisma migration with all new models - **DONE**
2. ✅ **Day 2**: Implement P0 endpoints (Goals, Portfolio History) - **DONE**
3. ✅ **Day 3**: Implement P1 endpoints (Market, Dividends, Points) - **DONE**
4. ✅ **Day 4**: Update iOS stores to use real APIs - **DONE** (GoalsStore, PointsStore, DashboardStore)
5. ✅ **Day 5**: Implement P2 endpoints (Tax, Advisors) - **DONE**
6. ✅ **Day 6**: Implement P3 endpoints (User Actions) - **DONE**
7. ✅ **Day 7**: Update iOS stores for P2/P3 APIs - **DONE** (DashboardStore, AdvisorStore)

### Deferred Items
- **Connected Broker Accounts**: Requires OAuth integration with Zerodha, Groww, etc.
- **AI Chat**: Requires AI/LLM integration (Claude API or similar)

---

## Completed Work Log

### 2026-01-31
- Added 24 new Prisma models (all priorities P0-P3)
- Created seed script for demo data (goals, points, market indices, portfolio history, dividends)
- Implemented Goals API with full CRUD + contributions (`/api/v1/me/goals`)
- Implemented Points API (`/api/v1/me/points`)
- Implemented Market Indices API (`/api/v1/market/indices`)
- Implemented Portfolio History API (`/api/v1/auth/me/portfolio/history`)
- Implemented Dividends API (`/api/v1/auth/me/dividends`)
- Fixed route collision: changed `/api/v1/users/*` to `/api/v1/me/*`
- Updated iOS stores: GoalsStore, PointsStore, DashboardStore

### 2026-01-31 (Session 2)
- **P2: Tax Summary API** (`/api/v1/me/taxes/summary`, `/api/v1/me/taxes/capital-gains`)
  - Created TaxesModule with service and controller
  - Returns LTCG/STCG realized/unrealized gains
  - Includes tax estimate calculation with Rs 1L LTCG exemption
  - Capital gains records endpoint for transaction history

- **P2: Advisors API** (`/api/v1/advisors`)
  - Created AdvisorsModule with service and controller
  - List advisors with filters (city, specialization, rating, verified, accepting new)
  - Get advisor profile by ID
  - Get and create advisor reviews
  - Get all specializations endpoint

- **P3: User Actions API** (`/api/v1/me/actions`)
  - Created ActionsModule with service and controller
  - Full CRUD for user actions/reminders
  - Priority-based sorting (URGENT > HIGH > MEDIUM > LOW)
  - Mark as read, dismiss, complete endpoints
  - Tracks unread count and high priority count

- **Seed Data**:
  - Added tax summaries for demo users
  - Created user actions (SIP due, rebalance, tax harvesting, etc.)
  - Created advisor profiles (Rahul Sharma CFP, Neha Mehta CFA)

### 2026-01-31 (Session 3)
- **iOS DashboardStore** - Added P2/P3 API integration:
  - Added `fetchTaxSummary()` method for `/api/v1/me/taxes/summary`
  - Added `fetchActions()` method for `/api/v1/me/actions`
  - API response models: `TaxSummaryAPIResponse`, `TaxEstimateResponse`, `CapitalGainResponse`
  - API response models: `ActionsAPIResponse`, `ActionAPIResponse`
  - Methods map API responses to native Swift models with fallback to mock data

- **iOS AdvisorStore** - Updated API response models for `/api/v1/advisors`:
  - Added `AdvisorsListResponse` wrapper for paginated response
  - Updated `AdvisorAPIResponse` to match backend format (displayName, city, totalReviews, isAcceptingNew, avatarUrl)
  - Updated `toAdvisor()` method with specialization string-to-enum mapping
  - Changed `fetchAdvisorsByRegion()` to use `city` query parameter

---

## Notes

- All mock data files are in `/platforms/ios-consumer/SparrowInvest/Services/`
- Most stores already have API fallback pattern - just need endpoints
- ProfileView has hardcoded values that need to be connected to stores
- Market data uses seeded mock values (would need NSE/BSE API for live data)
- **Route pattern**: Use `/api/v1/me/*` for current user endpoints to avoid UsersController collision
