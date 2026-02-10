# FA Portal Implementation Plan

## Current Status Assessment

### Existing Pages (UI Shells with Mock Data)

| Page | Status | Completeness |
|------|--------|--------------|
| Dashboard | Implemented | 70% - UI complete, mock data |
| Clients | Implemented | 40% - List view only, no detail/forms |
| Prospects | Implemented | 50% - Pipeline view, no forms |
| Transactions | Implemented | 40% - List view, no transaction forms |
| Funds | Implemented | 80% - Live API connected |
| Analysis | Implemented | 30% - UI shell, mock AI |
| Reports | Implemented | 40% - UI shell, no actual generation |
| Fund Detail | Implemented | 60% - Basic view |

### What's Implemented
- Basic layout with sidebar navigation
- Dark/light mode theming
- KPI cards and summary statistics
- List/table views for all entities
- Basic filtering and search
- Mock data for all entities

### What's Missing (Critical Gaps)

---

## Phase 1: Core Client Management (Priority: Critical)

### 1.1 Client Detail Page
**File:** `pages/advisor/clients/[id].tsx`

Features:
- [ ] 360-degree client view header
- [ ] Portfolio overview section
- [ ] Holdings breakdown (by asset class, fund house, sector)
- [ ] Performance chart (1M, 3M, 6M, 1Y, 3Y, 5Y)
- [ ] Active SIPs section
- [ ] Goals progress section
- [ ] Transaction history
- [ ] Documents section
- [ ] Notes/activity log
- [ ] Quick actions (Add investment, Start SIP, Withdraw)

### 1.2 Add/Edit Client Form
**File:** `pages/advisor/clients/new.tsx` and edit modal

Features:
- [ ] Personal details (Name, DOB, PAN, Aadhaar)
- [ ] Contact information (Email, Phone, Address)
- [ ] Bank account details
- [ ] Nominee information
- [ ] Risk profiling questionnaire
- [ ] Investment experience assessment
- [ ] FATCA declaration checkbox
- [ ] Document upload (PAN, Aadhaar, Photo, Address proof)

### 1.3 Client Portfolio View
**File:** `components/advisor/ClientPortfolio.tsx`

Features:
- [ ] Current value vs invested amount
- [ ] Total gains (realized + unrealized)
- [ ] XIRR calculation
- [ ] Asset allocation pie chart
- [ ] Holdings table with drill-down
- [ ] Fund-wise performance

---

## Phase 2: Goal-Based Planning (Priority: High)

### 2.1 Goals Management Page
**File:** `pages/advisor/clients/[id]/goals.tsx`

Features:
- [ ] Goal creation wizard
- [ ] Pre-defined templates (Retirement, Education, Home, Emergency)
- [ ] Custom goal support
- [ ] Goal progress visualization
- [ ] Investment mapping (link SIPs/lumpsum to goals)
- [ ] Gap analysis
- [ ] What-if scenarios

### 2.2 Goals Dashboard Widget
**File:** `components/advisor/GoalsDashboard.tsx`

Features:
- [ ] Goals summary cards
- [ ] On-track vs off-track indicators
- [ ] Progress bars
- [ ] Quick actions

---

## Phase 3: SIP Management (Priority: High)

### 3.1 SIP Dashboard
**File:** `pages/advisor/sips.tsx` or tab in client detail

Features:
- [ ] Active SIPs list
- [ ] SIP calendar view
- [ ] Upcoming SIPs
- [ ] Failed/bounced SIPs
- [ ] SIP performance

### 3.2 SIP Registration Form
**File:** `components/advisor/SIPForm.tsx`

Features:
- [ ] Fund selector
- [ ] Amount input
- [ ] Frequency selector (Daily, Weekly, Monthly)
- [ ] Date selection
- [ ] Step-up option
- [ ] Tenure/perpetual option
- [ ] Bank mandate setup

### 3.3 SIP Management Actions
Features:
- [ ] Pause/Resume SIP
- [ ] Modify amount/date
- [ ] Cancel SIP
- [ ] Step-up modification

---

## Phase 4: Transaction Workflow (Priority: Critical)

### 4.1 New Transaction Form
**File:** `components/advisor/TransactionForm.tsx`

Features:
- [ ] Client selector
- [ ] Transaction type (Buy, Sell, Switch, SIP, SWP, STP)
- [ ] Fund search and selector
- [ ] Amount/units input
- [ ] Folio selection (existing or new)
- [ ] Cut-off time display
- [ ] Order review and confirmation
- [ ] OTP verification

### 4.2 Transaction Detail View
**File:** `components/advisor/TransactionDetail.tsx`

Features:
- [ ] Order status timeline
- [ ] NAV and units allotted
- [ ] Payment status
- [ ] Folio information
- [ ] Related transactions

### 4.3 Bulk Transaction Upload
Features:
- [ ] CSV/Excel template
- [ ] Upload and validation
- [ ] Preview before submission
- [ ] Batch processing status

---

## Phase 5: Reporting Enhancement (Priority: High)

### 5.1 Report Generation Engine
Features:
- [ ] PDF generation (using react-pdf or similar)
- [ ] Excel export
- [ ] White-label branding (logo, colors, footer)
- [ ] Date range selection
- [ ] Preview before download

### 5.2 Report Types to Implement
- [ ] Portfolio Statement
- [ ] Transaction Statement
- [ ] Capital Gains Report (STCG/LTCG)
- [ ] SIP Summary
- [ ] Goal Progress Report
- [ ] Performance Report

### 5.3 Report Delivery
Features:
- [ ] Download as PDF/Excel
- [ ] Email to client (password protected)
- [ ] Schedule recurring reports

---

## Phase 6: AI & Analysis Enhancement (Priority: Medium)

### 6.1 Portfolio Health Score
Features:
- [ ] Diversification score
- [ ] Risk alignment score
- [ ] Cost efficiency score
- [ ] Goal progress score
- [ ] Overall portfolio health

### 6.2 Analysis Tools
- [ ] Overlap analysis (duplicate holdings across funds)
- [ ] Concentration risk detection
- [ ] Benchmark comparison
- [ ] Tax loss harvesting opportunities
- [ ] Rebalancing recommendations

### 6.3 Calculators Page
**File:** `pages/advisor/calculators.tsx`

Calculators:
- [ ] SIP Calculator
- [ ] Lumpsum Calculator
- [ ] Goal Calculator
- [ ] SWP Calculator
- [ ] Retirement Calculator
- [ ] Tax Calculator

---

## Phase 7: Prospect Management Enhancement (Priority: Medium)

### 7.1 Add Prospect Form
**File:** `components/advisor/ProspectForm.tsx`

Features:
- [ ] Basic details
- [ ] Potential AUM
- [ ] Lead source
- [ ] Initial notes
- [ ] Referrer information

### 7.2 Prospect to Client Conversion
Features:
- [ ] Convert button with validation
- [ ] Data transfer workflow
- [ ] Onboarding checklist
- [ ] Initial investment setup

### 7.3 Activity Tracking
Features:
- [ ] Log calls, emails, meetings
- [ ] Set follow-up tasks
- [ ] Activity timeline
- [ ] Reminders

---

## Phase 8: Communication (Priority: Medium)

### 8.1 Notification Center
**File:** `components/advisor/NotificationCenter.tsx`

Features:
- [ ] SIP due reminders
- [ ] SIP failure alerts
- [ ] Goal milestones
- [ ] KYC expiry alerts
- [ ] Market alerts

### 8.2 Communication Templates
Features:
- [ ] Email templates
- [ ] SMS templates (if integrated)
- [ ] Personalization tokens
- [ ] Template management

### 8.3 Client Communication
Features:
- [ ] Send email from portal
- [ ] Communication history
- [ ] Bulk communication

---

## Phase 9: Settings & Configuration (Priority: Low)

### 9.1 Advisor Profile
**File:** `pages/advisor/settings/profile.tsx`

Features:
- [ ] Personal details
- [ ] ARN/EUIN management
- [ ] Business information
- [ ] Contact details

### 9.2 Preferences
**File:** `pages/advisor/settings/preferences.tsx`

Features:
- [ ] Theme selection
- [ ] Notification preferences
- [ ] Default values
- [ ] Dashboard customization

### 9.3 Integrations (Future)
Features:
- [ ] BSE StAR MF setup
- [ ] Payment gateway setup
- [ ] Email service setup
- [ ] SMS gateway setup

---

## Phase 10: Compliance & Audit (Priority: Low)

### 10.1 Compliance Dashboard
Features:
- [ ] KYC status overview
- [ ] Risk suitability checks
- [ ] Nominee missing alerts
- [ ] Document expiry tracking

### 10.2 Audit Trail
Features:
- [ ] User activity log
- [ ] Transaction audit log
- [ ] Login history
- [ ] Data export for audits

---

## Implementation Priority Matrix

| Priority | Phase | Description |
|----------|-------|-------------|
| **Critical** | Phase 1 | Client Detail & Forms |
| **Critical** | Phase 4 | Transaction Workflow |
| **High** | Phase 2 | Goal-Based Planning |
| **High** | Phase 3 | SIP Management |
| **High** | Phase 5 | Reporting Enhancement |
| **Medium** | Phase 6 | AI & Analysis |
| **Medium** | Phase 7 | Prospect Enhancement |
| **Medium** | Phase 8 | Communication |
| **Low** | Phase 9 | Settings |
| **Low** | Phase 10 | Compliance |

---

## Technical Debt to Address

### Code Quality
- [ ] Extract FA color palette to shared utility
- [ ] Create reusable form components
- [ ] Create reusable card components
- [ ] Add TypeScript interfaces for all data models
- [ ] Add loading states to all pages
- [ ] Add error handling

### API Integration
- [ ] Connect clients to backend API
- [ ] Connect transactions to backend API
- [ ] Connect reports to backend API
- [ ] Add real-time data updates

### Testing
- [ ] Add component tests
- [ ] Add integration tests
- [ ] Add E2E tests for critical flows

---

## Recommended Implementation Order

### Sprint 1 (Foundation)
1. Client Detail Page
2. Add Client Form
3. Client Portfolio View

### Sprint 2 (Transactions)
4. Transaction Form
5. Transaction Detail
6. SIP Dashboard

### Sprint 3 (Goals & SIPs)
7. Goals Management
8. SIP Registration Form
9. SIP Actions

### Sprint 4 (Reports & Analysis)
10. Report Generation
11. Calculators
12. Analysis Enhancement

### Sprint 5 (Polish)
13. Prospect Enhancement
14. Communication
15. Settings & Compliance

---

## Files to Create

### Pages
```
pages/advisor/
├── clients/
│   ├── [id].tsx           # Client detail page
│   ├── [id]/goals.tsx     # Client goals
│   └── new.tsx            # Add client
├── sips.tsx               # SIP dashboard
├── calculators.tsx        # Financial calculators
└── settings/
    ├── profile.tsx
    └── preferences.tsx
```

### Components
```
components/advisor/
├── ClientPortfolio.tsx
├── ClientForm.tsx
├── GoalsDashboard.tsx
├── GoalForm.tsx
├── SIPForm.tsx
├── SIPCard.tsx
├── TransactionForm.tsx
├── TransactionDetail.tsx
├── CalculatorSIP.tsx
├── CalculatorGoal.tsx
├── NotificationCenter.tsx
└── ProspectForm.tsx
```

### Shared
```
utils/
├── faColors.ts            # Extract color palette
├── faTypes.ts             # TypeScript interfaces
└── calculations.ts        # Financial calculations
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | January 2026 | Initial implementation plan |
