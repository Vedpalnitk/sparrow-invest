# Sparrow Invest - Smart Portfolio Manager

## Project Overview
AI-powered mutual fund portfolio management platform with goal-aligned recommendations. The project consists of multiple platforms and services:
- **Next.js Web App** - Admin dashboard and user portal (port 3500)
- **iOS Consumer App** - Native SwiftUI mobile app for consumers (ios-consumer)
- **iOS FA App** - Native SwiftUI mobile app for Financial Advisors (ios-fa)
- **Android Consumer App** - Native Kotlin/Jetpack Compose app for consumers (android-consumer)
- **Android FA App** - Native Kotlin/Jetpack Compose app for Financial Advisors (android-fa)
- **Backend** - NestJS API service (port 3501)
- **ML Service** - Machine learning recommendation engine

## Project Structure
```
sparrow-invest/
├── platforms/
│   ├── web/                # Next.js web application
│   │   ├── src/
│   │   │   ├── components/ # Reusable React components
│   │   │   ├── context/    # React context providers
│   │   │   ├── pages/      # Next.js pages (Pages Router)
│   │   │   ├── services/   # API services
│   │   │   ├── styles/     # Global CSS and Tailwind
│   │   │   └── utils/      # Utility functions and constants
│   │   └── package.json
│   ├── ios-consumer/        # iOS consumer app (SwiftUI)
│   │   └── SparrowInvest/
│   │       ├── App/        # App entry point
│   │       ├── Models/     # Data models
│   │       ├── Views/      # SwiftUI views
│   │       ├── Components/ # Reusable components
│   │       ├── Services/   # API and state services
│   │       └── Utilities/  # Helpers and theme
│   ├── ios-fa/              # iOS FA app (SwiftUI)
│   │   └── SparrowInvestFA/
│   │       ├── App/        # App entry point
│   │       ├── Models/     # Data models
│   │       ├── Views/      # SwiftUI views
│   │       ├── Components/ # Reusable components
│   │       ├── Services/   # API and state services
│   │       └── Utilities/  # Helpers and theme
│   ├── android-consumer/    # Android consumer app (Kotlin/Compose)
│   │   └── app/src/main/java/com/sparrowinvest/consumer/
│   └── android-fa/         # Android FA app (Kotlin/Compose)
│       └── app/src/main/java/com/sparrowinvest/fa/
│           ├── ui/         # Compose UI (screens, components, navigation)
│           ├── data/       # Models, repositories
│           ├── core/       # Network, DI modules
│           └── MainActivity.kt
├── backend/                # NestJS API service (port 3501)
├── ml-service/             # ML recommendation engine
├── proto/                  # Protocol buffer definitions
├── docs/                   # Documentation
│   ├── design/            # Design guidelines
│   ├── ios/               # iOS-specific docs
│   └── phase-2/           # Phase 2 implementation
└── archived/              # Archived code (old mobile-v1)
```

## Frequently Used Commands

### Web App (Next.js)
- **Dev server**: `cd platforms/web && npm run dev`
- **Build**: `cd platforms/web && npm run build`
- **Lint**: `cd platforms/web && npm run lint`

### iOS Consumer App (SwiftUI)
- **Open in Xcode**: `open platforms/ios-consumer/SparrowInvest.xcodeproj` (or use XcodeGen with project.yml)
- **Generate project**: `cd platforms/ios-consumer && xcodegen generate`
- **Build**: `xcodebuild -project platforms/ios-consumer/SparrowInvest.xcodeproj -scheme SparrowInvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build`
- **Install & Run**: `xcrun simctl install "iPhone 17 Pro" <path-to-app> && xcrun simctl launch "iPhone 17 Pro" com.sparrowinvest.app`

### iOS FA App (SwiftUI)
- **Open in Xcode**: `open platforms/ios-fa/SparrowInvestFA.xcodeproj` (or use XcodeGen with project.yml)
- **Generate project**: `cd platforms/ios-fa && xcodegen generate`
- **Build**: `xcodebuild -project platforms/ios-fa/SparrowInvestFA.xcodeproj -scheme SparrowInvestFA -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build`

### Android FA App (Kotlin/Compose)
- **Build**: `cd platforms/android-fa && ./gradlew assembleDebug`
- **Install**: `adb install -r platforms/android-fa/app/build/outputs/apk/debug/app-debug.apk`
- **Run**: `adb shell am start -n com.sparrowinvest.fa/.MainActivity`
- **Build & Install**: `cd platforms/android-fa && ./gradlew installDebug`

> **Note**: Requires `JAVA_HOME` pointing to Android Studio's JDK:
> `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`

### Backend
- **Dev server**: `cd backend && npm run start:dev`
- **Database migrate**: `cd backend && npm run db:migrate`
- **Database seed**: `cd backend && npm run db:seed`
- **Prisma Studio**: `cd backend && npm run db:studio`

### ML Service
- **Start**: `cd ml-service && python -m app.main`

## Code Style & Conventions

- Use TypeScript for all new code
- 2-space indentation
- Single quotes for strings
- No semicolons (follow existing codebase style)
- Use functional components with hooks
- Prefer named exports over default exports for utilities

## Path Aliases

### Web App (tsconfig.json in platforms/web)
- `@/components/*` → `src/components/*`
- `@/context/*` → `src/context/*`
- `@/services/*` → `src/services/*`
- `@/utils/*` → `src/utils/*`
- `@/styles/*` → `src/styles/*`

### iOS App
Uses SwiftUI with standard Swift package structure in `platforms/ios-consumer/SparrowInvest/`

## Important Patterns

### Theming
- Web: Class-based dark mode with CSS custom properties (`:root.dark`)
- iOS: SwiftUI native theming with AppTheme utility
- Both support system preference detection and manual toggle

### API Integration
- MFAPI.in for Indian mutual fund NAV data
- Web API services in `platforms/web/src/services/`
- iOS API services in `platforms/ios-consumer/SparrowInvest/Services/`

### Subdomain Portal Separation
- `app.sparrow-invest.com` → FA portal only (admin routes blocked)
- `admin.sparrow-invest.com` → Admin portal only (advisor routes blocked)
- `localhost:3500` → Both portals (dev mode, no restrictions)
- Implemented via Next.js edge middleware (`platforms/web/middleware.ts`) reading `Host` header
- Defense-in-depth: client-side hostname guards in `AdminLayout.tsx`, `AdvisorLayout.tsx`, and `index.tsx`
- Env vars `NEXT_PUBLIC_APP_HOSTNAME` / `NEXT_PUBLIC_ADMIN_HOSTNAME` control behavior; unset = dev mode
- Vercel preview deployments fall into dev mode (full access)

### State Management
- Web: React Context API (no Redux), localStorage for persistence
- iOS: SwiftUI @Observable stores, UserDefaults for persistence

## Key Files

### Web App
- `platforms/web/middleware.ts` - Edge middleware for subdomain-based portal separation
- `platforms/web/src/pages/_app.tsx` - Next.js app wrapper with ThemeProvider
- `platforms/web/src/context/ThemeContext.tsx` - Web theme management
- `platforms/web/src/utils/v4-colors.ts` - V4 design system colors

### iOS Consumer App
- `platforms/ios-consumer/SparrowInvest/App/SparrowInvestApp.swift` - App entry point
- `platforms/ios-consumer/SparrowInvest/App/ContentView.swift` - Main content view
- `platforms/ios-consumer/SparrowInvest/Services/APIService.swift` - API integration
- `platforms/ios-consumer/SparrowInvest/Services/AuthManager.swift` - Authentication
- `platforms/ios-consumer/SparrowInvest/Services/FamilyStore.swift` - Family portfolio & client type
- `platforms/ios-consumer/SparrowInvest/Services/AdvisorStore.swift` - Advisor assignment management
- `platforms/ios-consumer/SparrowInvest/Views/Common/MainTabView.swift` - Main tab container, data loading
- `platforms/ios-consumer/SparrowInvest/Views/Home/HomeView.swift` - Dashboard with quick actions
- `platforms/ios-consumer/SparrowInvest/Views/Invest/ManagedInvestmentView.swift` - FA trade request form
- `platforms/ios-consumer/SparrowInvest/Models/TradeRequest.swift` - Trade request models
- `platforms/ios-consumer/SparrowInvest/Utilities/AppTheme.swift` - Theme management

### iOS FA App
- `platforms/ios-fa/SparrowInvestFA/App/SparrowInvestFAApp.swift` - App entry point
- `platforms/ios-fa/SparrowInvestFA/App/ContentView.swift` - Main content view

### Android FA App
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/MainActivity.kt` - App entry point
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/ui/navigation/NavGraph.kt` - Navigation setup
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/ui/navigation/Screen.kt` - Route definitions
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/core/network/ApiService.kt` - Retrofit API interface
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/data/model/Transaction.kt` - FATransaction model
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/data/repository/TransactionRepository.kt` - Transaction data layer
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/ui/transactions/TransactionsScreen.kt` - Transactions UI
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/ui/transactions/PlatformWebViewScreen.kt` - BSE/MFU WebView
- `platforms/android-fa/app/src/main/java/com/sparrowinvest/fa/ui/clients/ClientDetailScreen.kt` - Client details

## External APIs

### MFAPI.in (Mutual Fund API)
- Base URL: `https://api.mfapi.in`
- Get all funds: `GET /mf`
- Get fund details: `GET /mf/{schemeCode}`
- Returns NAV history for CAGR calculations

## Environment Setup

### Web App (.env.local)
```bash
# Subdomain-based portal separation (unset for local dev = full access)
NEXT_PUBLIC_APP_HOSTNAME=app.sparrow-invest.com
NEXT_PUBLIC_ADMIN_HOSTNAME=admin.sparrow-invest.com
```

### Backend (.env)
```bash
DATABASE_URL="postgresql://user:pass@localhost:5432/sparrowinvest"
JWT_SECRET="your-secret-key"
PORT=3501
```

### Android FA App
- Base URL configured in `core/network/NetworkModule.kt`
- Uses `10.0.2.2:3501` for emulator → localhost backend

## Gotchas & Common Issues

| Issue | Solution |
|-------|----------|
| Android build fails with "Java not found" | Set `JAVA_HOME` to Android Studio's JDK (see commands above) |
| Transactions screen shows JSON error | Ensure `FATransaction` model matches backend `TransactionResponseDto` (camelCase fields) |
| Backend status values mismatch | Backend uses title case (`Pending`, `Completed`), not uppercase (`PENDING`, `EXECUTED`) |
| iOS WebView cookies not persisting | Enable `setAcceptThirdPartyCookies()` on the WebView instance |
| Emulator can't reach backend | Use `10.0.2.2` instead of `localhost` for Android emulator |
| Admin routes 404 in production | Check `NEXT_PUBLIC_APP_HOSTNAME` — middleware blocks `/admin/*` on app subdomain |
| Middleware not running | `middleware.ts` must be at `platforms/web/middleware.ts` (project root, not `src/`) for Pages Router |

---

## Demo Users for Testing

All demo users use the format `firstname.lastname@demo.com` with password `Demo@123`:

| Email | Password | Name | Type | Description |
|-------|----------|------|------|-------------|
| `amit.verma@demo.com` | `Demo@123` | Amit Verma | **Self-service** | No FA, uses brokerage platforms |
| `priya.patel@demo.com` | `Demo@123` | Priya Patel | **Managed** | Patel Family head, has FA advisor |
| `rajesh.sharma@demo.com` | `Demo@123` | Rajesh Sharma | **Managed** | Sharma Family head, has FA advisor |

### FA (Advisor) Demo Users

| Email | Password | Name |
|-------|----------|------|
| `priya.sharma@sparrow-invest.com` | `Advisor@123` | Priya Sharma |
| `arun.mehta@sparrow-invest.com` | `Advisor@123` | Arun Mehta |
| `kavitha.nair@sparrow-invest.com` | `Advisor@123` | Kavitha Nair |

### User Types

1. **Self-service Users** (`clientType: "self"`)
   - Not linked to any Financial Advisor (FA)
   - Quick actions (Invest/Withdraw/SIP) show brokerage platform selection (Zerodha, Groww, etc.)
   - Can browse and research funds independently

2. **Managed Users** (`clientType: "managed"`)
   - Linked to an FA via `FAClient` record with `userId` field
   - Quick actions show `ManagedQuickActionSheet` directing to fund selection
   - Trade requests submitted to FA for execution via `ManagedInvestmentView`
   - Family members visible in portfolio view

### FA Client Families (Database)

**Patel Family:**
- SELF: Priya Patel (linked to `priya.patel@demo.com`)
- SPOUSE: Vikram Patel
- CHILD: Ananya Patel
- PARENT: Harish Patel

**Sharma Family:**
- SELF: Rajesh Sharma (linked to `rajesh.sharma@demo.com`)
- SPOUSE: Sunita Sharma
- CHILD: Arjun Sharma
- PARENT: Kamla Devi Sharma

### FA Portal API Patterns

| Endpoint Pattern | Description |
|------------------|-------------|
| `GET /api/v1/goals` | All goals for logged-in advisor |
| `GET /api/v1/clients/:clientId/goals` | Goals for specific client |
| `GET /api/v1/funds/live/search?q=HDFC` | Fund search (append "Direct Growth" for direct plans) |
| `POST /api/v1/sips/:id/pause` | Pause a SIP |
| `POST /api/v1/sips/:id/resume` | Resume a paused SIP |
| `POST /api/v1/sips/:id/cancel` | Cancel a SIP |

### FA Portal Components

- **FANotificationProvider**: Must wrap app in `_app.tsx` for toast notifications. Already configured.
- **TransactionFormModal**: Reusable modal for Buy/SIP/Redeem/Switch transactions
- **FACard, FATintedCard, FAInfoTile**: Themed card components for FA Portal

---

## iOS App - User Flow Architecture

### Login & Data Loading Flow

1. User logs in via `AuthManager.loginWithEmail()`
2. `MainTabView.task` triggers `familyStore.loadFromAPI()`
3. API returns `clientType` ("self" or "managed") and optional `advisor` info
4. `FamilyStore` sets/clears `advisor` based on response
5. `MainTabView` calls `advisorStore.setAssignedAdvisor()` or `removeAssignedAdvisor()`

### Key Files for User Type Detection

| File | Purpose |
|------|---------|
| `Services/FamilyStore.swift` | Stores `clientType` and `advisor` info from API |
| `Services/AdvisorStore.swift` | Manages `assignedAdvisorId` and `hasAssignedAdvisor` |
| `Views/Common/MainTabView.swift` | Orchestrates data loading on app launch |
| `Views/Home/HomeView.swift` | `QuickActionsRow` checks `isManagedClient` for flow routing |

### Managed User Investment Flow

1. **HomeView** → Quick action button (Invest/Withdraw/SIP)
2. **ManagedQuickActionSheet** → Shows advisor info, "Browse Funds" button
3. **ExploreView** → User selects a fund
4. **ManagedInvestmentView** → User enters amount, submits trade request
5. **API** → `POST /api/v1/transactions/trade-request` creates `FATransaction` with PENDING status
6. **Confirmation** → User sees success message that request sent to advisor

### Key iOS Files for FA Trade Flow

| File | Purpose |
|------|---------|
| `Models/TradeRequest.swift` | `TradeRequest` and `TradeRequestResponse` models |
| `Services/APIService.swift` | `submitTradeRequest()` and `getMyTradeRequests()` methods |
| `Views/Invest/ManagedInvestmentView.swift` | Investment form for managed users |
| `Views/Home/HomeView.swift` | `ManagedQuickActionSheet` component |

### Backend Endpoints for Trade Requests

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/transactions/trade-request` | POST | Submit trade request to FA |
| `/api/v1/transactions/my-requests` | GET | Get user's trade request history |
| `/api/v1/auth/me/portfolio` | GET | Returns `clientType`, `advisor`, `family` data |

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **Frontend Design** | `/frontend-design` | Create distinctive, production-grade frontend interfaces with high design quality. Use for building web components, pages, or redesigning existing UI. |
| **Feature Development** | `/feature-dev` | Guided feature development with codebase understanding and architecture focus. |
| **Code Review** | `/code-review` | Review pull requests for bugs, security, and code quality. |
| **CLAUDE.md Revision** | `/revise-claude-md` | Update CLAUDE.md with learnings from the current session. |
| **CLAUDE.md Improver** | `/claude-md-improver` | Audit and improve CLAUDE.md files in the repository. |

### Usage
Invoke skills by typing the command (e.g., `/frontend-design`) followed by your request.

## Additional Context

Design guidelines and platform-specific rules are in `.claude/rules/`:
- `.claude/rules/design-checklist.md` - iOS/Web design system (glass cards, theming)
- `.claude/rules/mobile/ios.md` - iOS SwiftUI patterns
- `.claude/rules/security.md` - Security guidelines

Also see:
- `docs/design/design-guidelines.md` - Brand colors, typography, components
- `docs/BUILD_NOTES.md` - Build history and decisions
