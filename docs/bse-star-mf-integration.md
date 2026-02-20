# BSE StAR MF Integration — Technical Reference

## Overview

Sparrow Invest integrates with BSE StAR MF (Stock Exchange Transactions and Reporting for Mutual Funds) to enable real mutual fund transactions — purchases, redemptions, SIPs, XSIPs, STPs, SWPs, switches, mandates, payments, and compliance uploads. A partner MFD (Mutual Fund Distributor) with existing ARN and BSE registration provides the credentials.

BSE StAR MF supports dual protocols:
- **SOAP 1.2** (legacy) — used for order entry, SIP registration, additional services
- **REST/JSON** (newer) — used for client registration, payments, STP, mandate status

---

## Architecture

### Backend Module

All BSE logic lives in `backend/src/bse-star-mf/` as a self-contained NestJS module (`BseStarMfModule`), registered in `app.module.ts`.

```
backend/src/bse-star-mf/
├── bse-star-mf.module.ts           # Module definition (controllers, providers, exports)
├── core/                           # Infrastructure layer
│   ├── bse-config.ts               # Endpoint URLs, timeouts, config
│   ├── bse-http.client.ts          # Dual-protocol HTTP client (SOAP + REST)
│   ├── bse-soap.builder.ts         # SOAP 1.2 envelope construction
│   ├── bse-session.manager.ts      # Token cache + auto-refresh
│   ├── bse-crypto.service.ts       # AES-256-GCM credential encryption
│   ├── bse-error.mapper.ts         # BSE error codes → NestJS exceptions
│   ├── bse-reference-number.service.ts  # Unique YYYYMMDD<memberid>NNNNNN
│   └── constants/
│       ├── endpoints.ts            # All BSE URL constants
│       ├── error-codes.ts          # Error code → message map
│       ├── tax-status.ts           # 77 tax status codes
│       ├── country-state.ts        # Country/state code lookups
│       ├── bank-codes.ts           # Direct + nodal bank codes
│       └── occupation-codes.ts     # Occupation codes
├── auth/
│   └── bse-auth.service.ts         # getPassword (5 session types)
├── credentials/
│   ├── bse-credentials.service.ts  # CRUD encrypted partner credentials
│   └── bse-credentials.controller.ts  # Admin: set/update/test credentials
├── mocks/
│   ├── bse-mock.service.ts         # Mock BSE responses for dev
│   └── bse-mock.interceptor.ts     # Intercept when BSE_MOCK_MODE=true
├── client-registration/
│   ├── bse-ucc.service.ts          # UCC registration (Enhanced API, REST)
│   ├── bse-fatca.service.ts        # FATCA upload (SOAP, flag 01)
│   ├── bse-ckyc.service.ts         # CKYC upload (SOAP, flag 13)
│   ├── bse-client-registration.controller.ts
│   └── dto/
│       └── register-ucc.dto.ts     # UCC + FATCA + CKYC DTOs
├── mandates/
│   ├── bse-mandate.service.ts      # Register, status, e-NACH auth, shift
│   ├── bse-mandates.controller.ts
│   └── dto/
│       └── register-mandate.dto.ts
├── orders/
│   ├── bse-order.service.ts        # Purchase/redemption (SOAP orderEntryParam)
│   ├── bse-switch.service.ts       # Switch orders (SOAP switchOrderEntryParam)
│   ├── bse-spread.service.ts       # Spread/overnight (SOAP spreadOrderEntryParam)
│   ├── bse-orders.controller.ts
│   └── dto/
│       └── place-order.dto.ts      # PlaceOrderDto, PlaceSwitchDto, PlaceSpreadDto
├── payments/
│   ├── bse-payment.service.ts      # Single Payment API (REST)
│   ├── bse-payments.controller.ts
│   └── dto/
│       └── initiate-payment.dto.ts
├── systematic/
│   ├── bse-sip.service.ts          # SIP registration (SOAP sipOrderEntryParam)
│   ├── bse-xsip.service.ts         # XSIP/ISIP (SOAP xsipOrderEntryParam)
│   ├── bse-stp.service.ts          # Enhanced STP (REST)
│   ├── bse-swp.service.ts          # SWP (SOAP flags 08/10)
│   ├── bse-systematic.controller.ts
│   └── dto/
│       └── register-sip.dto.ts
├── reports/
│   ├── bse-reports.service.ts      # Order status, allotment, redemption statements
│   ├── bse-child-orders.service.ts # Child order details for SIP/XSIP/STP/SWP
│   ├── bse-reports.controller.ts
│   └── dto/
│       └── report-query.dto.ts
├── uploads/
│   ├── bse-upload.service.ts       # AOF, mandate scan, cheque image upload
│   └── bse-uploads.controller.ts
├── masters/
│   ├── bse-masters.service.ts      # Scheme master sync, bank codes, tax status
│   └── bse-masters.controller.ts
└── jobs/
    ├── bse-session-refresh.job.ts      # Proactive token refresh
    ├── bse-mandate-status-poll.job.ts  # Every 30 min: poll pending mandate statuses
    ├── bse-order-status-poll.job.ts    # Every 15 min: poll pending order statuses
    ├── bse-allotment-sync.job.ts       # Weekdays 9pm: nightly allotment reconciliation
    └── bse-scheme-master-sync.job.ts   # Sunday 2am: weekly scheme master sync
```

**Total backend files: 54**

### Frontend

```
platforms/web/src/
├── pages/advisor/bse/
│   ├── setup.tsx                       # BSE credential configuration
│   ├── clients.tsx                     # UCC registration dashboard
│   ├── clients/[id]/register.tsx       # 5-step UCC registration wizard
│   ├── mandates.tsx                    # Mandate list + create modal
│   ├── mandates/[id].tsx               # Mandate detail (timeline, e-NACH, shift)
│   ├── orders.tsx                      # BSE orders dashboard
│   ├── orders/[id].tsx                 # Order detail (timeline, payment, allotment)
│   ├── reports.tsx                     # Tabbed report viewer + CSV export
│   └── scheme-master.tsx              # Searchable scheme browser
├── components/bse/
│   ├── BseStatusBadge.tsx              # Status badge component (28 statuses)
│   ├── BseOrderTimeline.tsx            # Horizontal order lifecycle timeline
│   ├── BseSchemePicker.tsx             # Autocomplete scheme search/select
│   ├── BseOrderPlacementModal.tsx      # Place purchase/redeem/switch/spread
│   └── BsePaymentModal.tsx             # Payment mode selection + initiation
└── services/api.ts                     # bseApi namespace (~50 endpoint methods)
```

**Total frontend files: 14**

### Modified Existing Files

| File | Changes |
|------|---------|
| `backend/prisma/schema.prisma` | 10 new BSE models + relations on User, FAClient |
| `backend/src/app.module.ts` | Import BseStarMfModule |
| `backend/src/transactions/transactions.service.ts` | Added `executeViaBse()` bridge method |
| `backend/src/transactions/transactions.controller.ts` | Added `POST :id/execute-bse` endpoint |
| `backend/src/sips/sips.service.ts` | Added `registerWithBse()` bridge method |
| `backend/src/sips/sips.controller.ts` | Added `POST :id/register-bse` endpoint |
| `platforms/web/src/services/api.ts` | Added `bseApi` namespace + bridge methods |
| `platforms/web/src/pages/advisor/settings.tsx` | Added BSE tab with navigation cards |
| `platforms/web/src/pages/advisor/transactions.tsx` | Added BSE column + Execute button |
| `platforms/web/src/pages/advisor/sips.tsx` | Added BSE registration button |
| `platforms/web/src/pages/advisor/clients/[id].tsx` | Added BSE Registration tab |
| `backend/.env.example` | Added BSE env vars section |

---

## Database Models (Prisma)

10 new models added to `backend/prisma/schema.prisma`:

| Model | Purpose | Key Fields |
|-------|---------|------------|
| `BsePartnerCredential` | Encrypted BSE credentials per advisor | `userId`, `memberId`, `encryptedPassword`, `arn`, `euin`, `isActive` |
| `BseSessionToken` | Cached auth tokens with TTL | `advisorId`, `sessionType`, `token`, `expiresAt` |
| `BseUccRegistration` | Maps FAClient → BSE UCC client code | `clientId` (unique), `uccClientCode`, `status`, `fatcaStatus`, `ckycStatus` |
| `BseMandate` | Mandate records (XSIP/ISIP/NetBanking) | `clientId`, `advisorId`, `mandateId`, `mandateType`, `amount`, `status`, `umrn`, `authUrl` |
| `BseOrder` | All BSE orders | `clientId`, `advisorId`, `transactionId?`, `sipId?`, `mandateId?`, `orderType`, `status`, `bseOrderNumber`, `schemeCode`, `amount`, `transCode` |
| `BseChildOrder` | SIP/XSIP/STP/SWP installment records | `bseOrderId`, `installmentNo`, `orderNumber`, `status`, `units`, `nav`, `amount` |
| `BsePayment` | Payment records | `bseOrderId`, `paymentMode`, `amount`, `status`, `redirectUrl`, `bankCode` |
| `BseApiLog` | Audit log of BSE API calls | `advisorId`, `endpoint`, `method`, `requestSummary`, `responseCode`, `duration` |
| `BseSchemeMaster` | BSE scheme reference data | `schemeCode`, `isin`, `schemeName`, `amcCode`, `purchaseAllowed`, `sipAllowed`, `minPurchaseAmt` |
| `BseBankMaster` | Bank codes for payment modes | `bankCode`, `bankName`, `paymentMode`, `isActive` |

### Key Relations

- `User` → `bseCredential` (1:1 via `BsePartnerCredential`)
- `FAClient` → `bseUccRegistration` (1:1), `bseMandates` (1:N), `bseOrders` (1:N)
- `BseOrder` → `bsePayments` (1:N), `bseChildOrders` (1:N)
- `BseOrder` → `FATransaction` (optional FK via `transactionId`)
- `BseOrder` → `FASIP` (optional FK via `sipId`)

### Enums

```
BseOrderType: PURCHASE, REDEMPTION, SIP, XSIP, STP, SWP, SWITCH, SPREAD
BseOrderStatus: CREATED, SUBMITTED, ACCEPTED, REJECTED, CANCELLED, PAYMENT_PENDING, PAYMENT_SUCCESS, PAYMENT_FAILED, ALLOTTED, FAILED
BseMandateType: XSIP, ISIP, NET_BANKING
BseMandateStatus: CREATED, SUBMITTED, APPROVED, REJECTED, CANCELLED, EXPIRED, SHIFTED
BsePaymentMode: DIRECT, NODAL, NEFT, UPI
BsePaymentStatus: INITIATED, SUCCESS, FAILED, EXPIRED
BseSessionType: ORDER_ENTRY, ADDITIONAL_SERVICES, FILE_UPLOAD, MANDATE_STATUS, CHILD_ORDER
```

---

## API Endpoints

### Credentials (`/api/v1/bse/credentials`)
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/` | Get BSE connection status |
| POST | `/` | Set/update BSE credentials |
| POST | `/test` | Test BSE connection |

### UCC Registration (`/api/v1/bse/ucc`)
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/:clientId` | Get BSE registration status |
| POST | `/:clientId/register` | Submit UCC registration |
| PUT | `/:clientId` | Modify existing UCC |
| POST | `/:clientId/fatca` | Upload FATCA declaration |
| POST | `/:clientId/ckyc` | Upload CKYC data |

### Mandates (`/api/v1/bse/mandates`)
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/` | List mandates (filter: clientId, status) |
| POST | `/` | Register new mandate |
| GET | `/:id` | Get mandate detail |
| GET | `/:id/auth-url` | Get e-NACH authentication URL |
| POST | `/:id/refresh-status` | Poll BSE for latest status |
| POST | `/:id/shift` | Shift mandate |

### Orders (`/api/v1/bse/orders`)
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/` | List orders (filter: clientId, status, orderType) |
| POST | `/purchase` | Place lumpsum purchase |
| POST | `/redeem` | Place redemption |
| POST | `/switch` | Place switch order |
| POST | `/spread` | Place spread/overnight order |
| GET | `/:id` | Get order detail |
| POST | `/:id/cancel` | Cancel order |

### Payments (`/api/v1/bse/payments`)
| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/:orderId` | Initiate payment |
| GET | `/:orderId/status` | Check payment status |
| POST | `/callback` | Payment callback webhook (public) |

### Systematic Plans (`/api/v1/bse/systematic`)
| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/sip` | Register SIP |
| POST | `/xsip` | Register XSIP/ISIP |
| POST | `/stp` | Register STP |
| POST | `/swp` | Register SWP |
| POST | `/:id/cancel` | Cancel systematic plan |
| GET | `/:id/child-orders` | Get installment history |

### Reports (`/api/v1/bse/reports`)
| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/order-status` | Query order status report |
| POST | `/allotment` | Query allotment statement |
| POST | `/redemption` | Query redemption statement |
| GET | `/child-orders/:regnNo` | Get child order details |

### Uploads (`/api/v1/bse/uploads`)
| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/aof` | Upload AOF image |
| POST | `/mandate-scan` | Upload mandate scan |
| POST | `/cheque` | Upload cheque image |

### Masters (`/api/v1/bse`)
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/scheme-master` | Search BSE schemes |
| POST | `/scheme-master/sync` | Trigger scheme master sync |
| GET | `/banks` | List supported banks by payment mode |
| GET | `/masters/tax-status` | Tax status code reference |

### Bridge Endpoints (existing controllers)
| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/api/v1/transactions/:id/execute-bse` | Execute pending FATransaction via BSE |
| POST | `/api/v1/sips/:id/register-bse` | Register active FASIP with BSE |

---

## Order Lifecycle

```
Advisor places order → FATransaction (PENDING)
  → BseOrder (CREATED)
  → Submit to BSE → BseOrder (SUBMITTED → ACCEPTED)
  → Initiate payment → BsePayment (INITIATED → SUCCESS)
  → BSE allots units → BseOrder (ALLOTTED)
  → Update FATransaction (COMPLETED) + FAHolding (updated units/value)
```

---

## Session Management

| Session Type | BSE Method | Lifetime | Cache Strategy |
|---|---|---|---|
| ORDER_ENTRY | `getPassword` (MFOrder.svc) | 60 min | DB cache, cron refresh 5min before expiry |
| ADDITIONAL_SERVICES | `getPassword` (MFUploadService.svc) | 5 min | JIT refresh, cache 4min |
| FILE_UPLOAD | `PasswordRequest` | Per-request | No cache |
| MANDATE_STATUS | `GetAccessToken` | Per-request | No cache |
| CHILD_ORDER | `GetPasswordForChildOrder` | Per-request | No cache |

Concurrent request dedup via in-memory `Map<string, Promise<string>>`.

---

## Background Jobs (Cron)

| Job | Schedule | Purpose |
|-----|----------|---------|
| `BseSessionRefreshJob` | Every 50 min | Proactive token refresh |
| `BseMandateStatusPollJob` | Every 30 min | Poll BSE for pending mandate statuses |
| `BseOrderStatusPollJob` | Every 15 min | Poll BSE for pending order statuses + allotment data |
| `BseAllotmentSyncJob` | Weekdays 9pm | Nightly allotment reconciliation (7-day lookback) |
| `BseSchemeMasterSyncJob` | Sunday 2am | Weekly scheme master refresh |

All jobs skip execution when `BSE_MOCK_MODE=true`.

---

## Environment Variables

```bash
# ---- BSE StAR MF Integration ----
# Generate key: node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
# BSE_ENCRYPTION_KEY=<32-byte-base64-key>
BSE_MOCK_MODE=true                              # true for dev, false for UAT/prod
BSE_BASE_URL=https://bsestarmfdemo.bseindia.com # demo for UAT, live URL for prod
BSE_CALLBACK_URL=http://localhost:3801/api/v1/bse/payments/callback
```

---

## Security

- BSE credentials AES-256-GCM encrypted at rest (`BseCryptoService`), key in `BSE_ENCRYPTION_KEY` env var
- API logs sanitized — no passwords, tokens, or PAN numbers stored in `BseApiLog`
- Credential endpoints never return actual passwords to frontend
- Transaction reference numbers have unique DB constraint (idempotency)
- `@Public()` decorator only on payment callback endpoint; all others require JWT via `JwtAuthGuard`
- Client access verified on every request via `verifyClientAccess()` (ensures advisor owns the client)

---

## Mock Mode

When `BSE_MOCK_MODE=true` (default for local dev):
- `BseMockService` returns simulated BSE responses (success/failure scenarios)
- `BseMockInterceptor` intercepts BSE API calls before they reach the network
- All cron jobs are skipped
- Orders get mock BSE order numbers, mandates get mock mandate IDs
- Allows full local development without BSE UAT credentials

---

## Frontend Pages

| Route | Page | Purpose |
|-------|------|---------|
| `/advisor/bse/setup` | Setup | BSE credential configuration + test connection |
| `/advisor/bse/clients` | Clients | UCC registration dashboard (all clients with BSE status) |
| `/advisor/bse/clients/[id]/register` | Register | 5-step UCC registration wizard |
| `/advisor/bse/mandates` | Mandates | Mandate list + create modal |
| `/advisor/bse/mandates/[id]` | Mandate Detail | Status timeline, e-NACH auth URL, shift |
| `/advisor/bse/orders` | Orders | BSE orders dashboard with expandable rows |
| `/advisor/bse/orders/[id]` | Order Detail | Order timeline, payment, allotment |
| `/advisor/bse/reports` | Reports | Tabbed viewer (order status, allotment, redemption) + CSV export |
| `/advisor/bse/scheme-master` | Scheme Master | Searchable scheme browser with eligibility flags |

### Reusable Components

| Component | Location | Usage |
|-----------|----------|-------|
| `BseStatusBadge` | `components/bse/` | Color-coded status pill (28 status values) |
| `BseOrderTimeline` | `components/bse/` | Horizontal lifecycle: Created → Submitted → Accepted → Payment → Allotted |
| `BseSchemePicker` | `components/bse/` | Autocomplete scheme search with debounce (300ms) |
| `BseOrderPlacementModal` | `components/bse/` | Place BSE order (4 types: purchase/redeem/switch/spread) |
| `BsePaymentModal` | `components/bse/` | Initiate payment (4 modes: DIRECT/NODAL/NEFT/UPI) |

### Integration Points in Existing Pages

- **Settings** (`/advisor/settings`) — BSE tab with 6 navigation cards linking to BSE pages
- **Transactions** (`/advisor/transactions`) — BSE column with "Execute BSE" button for pending transactions
- **SIPs** (`/advisor/sips`) — "BSE" button for active SIPs to register with BSE
- **Client Detail** (`/advisor/clients/[id]`) — BSE Registration tab showing UCC/FATCA/CKYC status

---

## UCC Registration Wizard Steps

The 5-step wizard at `/advisor/bse/clients/[id]/register`:

1. **Personal Details** — Pre-filled from FAClient (name, email, phone, PAN, DOB, address, gender, tax status, occupation, state)
2. **Bank Account** — Bank name, BSE bank code, account number, account type (Savings/Current/NRE/NRO), IFSC, MICR
3. **Nominee Details** — Name, relationship, percentage, address
4. **FATCA Declaration** — Income source, occupation, PEP status, gross annual income range, source of wealth, net worth
5. **Review & Submit** — Read-only summary with edit buttons per section, submit calls `bseApi.ucc.register()` + `bseApi.ucc.uploadFatca()`

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `fast-xml-parser` | SOAP XML response parsing (zero-dep, lightweight) |
| `@nestjs/schedule` | Cron job scheduling (already existed in project) |

---

## Testing Strategy

1. **Mock mode** — `BSE_MOCK_MODE=true` for all local development
2. **UAT integration** — Set `BSE_MOCK_MODE=false`, configure partner credentials, point to `bsestarmfdemo.bseindia.com`
3. **E2E scenario** — Set credentials → Register UCC → Register mandate → Place purchase → Pay → Verify allotment → Check FAHolding update

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Separate BSE models vs extending existing | Separate with FK links | BSE has its own lifecycle states; avoids polluting FA models |
| SOAP handling | Raw XML templates + `fast-xml-parser` | BSE SOAP is non-standard (pipe-separated params); SOAP libraries add bloat |
| Session storage | PostgreSQL (not Redis) | Low-frequency reads; avoids Redis hard dependency |
| Payment handling | Webhook + polling fallback | BSE callbacks may be unreliable |
| Credential security | AES-256-GCM (Node.js crypto) | No new dependencies; passwords encrypted at rest |
| Mock mode | Interceptor-based | Full local development without BSE UAT access |
| Bridge pattern | FKs on BseOrder → FATransaction/FASIP | Existing workflows continue to work; BSE is additive |
