# Screenshot Brain — Complete Application Documentation

> **Version:** 1.0.0+1  
> **Platform:** Android, iOS, Web, Windows, Linux  
> **Tech Stack:** Flutter + Riverpod + Isar + Google ML Kit  
> **Architecture:** Feature-first, Provider-driven, Offline-first  

---

## Table of Contents

1. [Overview](#1-overview)
2. [Tech Stack & Architecture](#2-tech-stack--architecture)
3. [Data Models](#3-data-models)
4. [Navigation & Routing](#4-navigation--routing)
5. [Services Layer](#5-services-layer)
6. [State Management & Providers](#6-state-management--providers)
7. [Screens & Features](#7-screens--features)
8. [Design System](#8-design-system)
9. [Scan Pipeline](#9-scan-pipeline)
10. [Categorization Engine](#10-categorization-engine)
11. [Expense Detection & Extraction](#11-expense-detection--extraction)
12. [Settings & Configuration](#12-settings--configuration)
13. [Permissions Flow](#13-permissions-flow)

---

## 1. Overview

**Screenshot Brain** is a privacy-focused AI assistant that automatically organizes screenshots, extracts useful information, categorizes them, and tracks expenses — all **entirely on-device** with no cloud dependency.

### Core Value Proposition

| Problem | Solution |
|---------|----------|
| Chaotic screenshot gallery | Auto-scan, categorize, and organize |
| Manual sorting of receipts/bills | Automatic expense detection & tracking |
| Finding information in screenshots | Full-text OCR search with highlighting |
| Privacy concerns with cloud AI | 100% on-device processing (Google ML Kit) |
| Tracking UPI/card payments | Structured expense extraction from payment screenshots |

### Key Numbers

- **11** smart categories (keyword-scored)
- **7** expense sub-categories
- **5** regex patterns for amount extraction
- **5** configurable scan intervals (6–72 hours)
- **10** search suggestion chips
- **2** Isar collections (ScreenshotModel, ExpenseModel)

---

## 2. Tech Stack & Architecture

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.6.1 | State management |
| `go_router` | ^14.8.1 | Declarative routing |
| `isar` | ^3.1.0+1 | Embedded NoSQL database |
| `isar_flutter_libs` | ^3.1.0+1 | Isar runtime libraries |
| `google_mlkit_text_recognition` | ^0.14.0 | On-device OCR |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `photo_manager` | ^3.6.0 | Photo library access |
| `intl` | ^0.20.2 | Date/number formatting |
| `share_plus` | ^10.1.4 | Share functionality |
| `path_provider` | ^2.1.5 | File system paths |
| `image_picker` | ^1.1.2 | Image selection |

### Architecture Pattern

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp.router config
├── core/
│   ├── router/app_router.dart         # Route definitions
│   ├── theme/                         # Design system & theming
│   ├── design/tokens.dart             # Spacing, radii, sizes, animations
│   ├── components/                    # Reusable component library
│   └── widgets/                       # Legacy widget wrappers
├── features/                          # Feature modules
│   ├── home/                          # Dashboard
│   ├── screenshots/                   # List, detail, viewer
│   ├── search/                        # Search experience
│   ├── categories/                    # Category browsing
│   ├── expenses/                      # Expense tracking
│   ├── settings/                      # App settings
│   ├── splash/                        # Splash screen
│   └── permissions/                   # Permission requests
├── services/                          # Business logic services
│   ├── database_service.dart
│   ├── ocr_service.dart
│   ├── categorization_service.dart
│   ├── expense_extraction_service.dart
│   ├── screenshot_scanner_service.dart
│   └── permission_service.dart
└── shared/models/                     # Isar data models
    ├── screenshot_model.dart
    ├── screenshot_model.g.dart        # Auto-generated
    ├── expense_model.dart
    └── expense_model.g.dart           # Auto-generated
```

**Data Flow:**
```
User Action → Provider (Riverpod) → Repository → Isar Database
                                              → Service (OCR/Categorization)
```

---

## 3. Data Models

### ScreenshotModel (Isar Collection)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | `Id` (int) | Auto-increment | Primary key |
| `filePath` | `String` | — | Absolute file path on device |
| `thumbnailPath` | `String?` | null | Optional thumbnail path |
| `extractedText` | `String?` | null | OCR-extracted text content |
| `category` | `String?` | null | Assigned category name |
| `createdAt` | `DateTime` | — | File modification timestamp |
| `fileSize` | `int?` | null | File size in bytes |
| `width` | `int?` | null | Image width (not currently set) |
| `height` | `int?` | null | Image height (not currently set) |
| `isProcessed` | `bool` | false | Whether OCR + categorization completed |
| `isExpense` | `bool` | false | Whether expense data was detected |

### ExpenseModel (Isar Collection)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | `Id` (int) | Auto-increment | Primary key |
| `screenshotId` | `int` | — | FK to ScreenshotModel.id |
| `amount` | `double?` | null | Extracted monetary amount |
| `merchant` | `String?` | null | Extracted merchant/vendor name |
| `expenseDate` | `DateTime?` | null | Extracted transaction date |
| `category` | `String?` | null | Expense sub-category (Food, Travel, etc.) |
| `description` | `String?` | null | Truncated OCR text (200 chars) |
| `createdAt` | `DateTime` | — | Record creation timestamp |

### ScreenshotItem (Presentation Model)

A non-Isar data class used by the UI layer, with computed getters:
- `categoryDisplay` → Returns `category ?? 'Uncategorized'`
- `dateDisplay` → Returns relative date: "Today", "Yesterday", "X days ago", or `dd/MM/yyyy`

### ExpenseItem (Presentation Model)

A non-Isar data class with computed getters:
- `amountDisplay` → Returns formatted: `₹1,234.00` or `'N/A'`
- `dateDisplay` → Returns formatted: `dd MMM yyyy`
- `monthLabel` → Returns: `MMM yyyy`

---

## 4. Navigation & Routing

Using **GoRouter** with 11 routes:

| Path | Screen | Parameters | Description |
|------|--------|------------|-------------|
| `/` | `SplashScreen` | — | Animated splash, checks permissions |
| `/permissions` | `PermissionScreen` | — | Gallery permission request |
| `/home` | `HomeDashboardScreen` | — | Main dashboard with stats & actions |
| `/screenshots` | `ScreenshotListScreen` | — | Full screenshot grid |
| `/screenshots/:id` | `ScreenshotDetailScreen` | `id` | Screenshot detail & extracted text |
| `/viewer/:id` | `ScreenshotViewerScreen` | `id`, `?category=` | Full-screen gallery viewer |
| `/search` | `SearchScreen` | — | Full-text search with suggestions |
| `/categories` | `CategoriesScreen` | — | Category grid overview |
| `/categories/:name` | `CategoryScreenshotsScreen` | `name` | Screenshots in a category |
| `/expenses` | `ExpenseDashboardScreen` | — | Expense tracking dashboard |
| `/settings` | `SettingsScreen` | — | App configuration |

**Navigation Flow:**
```
Splash → Permission (if needed) → Home → {Search, Categories, Expenses, Screenshots, Settings}
                                              ↓
                                         Detail → Viewer
```

---

## 5. Services Layer

### DatabaseService

Singleton managing the Isar database lifecycle.

- `init()` → Opens Isar with `ScreenshotModelSchema` and `ExpenseModelSchema`
- `db` → Static accessor to the Isar instance
- Database file stored in `getApplicationDocumentsDirectory()`
- Inspector enabled for debugging

### OcrService

Wrapper around Google ML Kit `TextRecognizer`.

- `extractText(String imagePath)` → OCR from file path
- `extractTextFromFile(File imageFile)` → OCR from File object
- `dispose()` → Closes the recognizer to free resources

### CategorizationService

Keyword-based scoring engine for classifying screenshots.

- **11 categories** with keyword dictionaries (see [Section 10](#10-categorization-engine))
- `categorize(text)` → Returns the best-matching category name
- `isExpense(text)` → Boolean check for expense-related keywords
- Scoring: each keyword match adds `keyword.length` to the category score
- Category with highest score wins; returns `'Other'` if no matches

### ExpenseExtractionService

Regex-based extraction of structured financial data.

- `extractAmount(text)` → Detects `Rs.`, `INR`, `₹`, `$`, `USD` formats
- `extractMerchant(text)` → Detects "paid to X", "sent to X", "from X" patterns
- `extractDate(text)` → Detects `dd/mm/yyyy`, `dd Mon yyyy`, `Mon dd, yyyy`
- `extractExpense(text, screenshotId)` → Creates a complete `ExpenseModel`
- `_determineExpenseCategory(text)` → Classifies expense into: Food, Travel, Shopping, Bills, Healthcare, Entertainment, Other

### ScreenshotScannerService

Device screenshot discovery using `photo_manager`.

- Discovers albums containing "screenshot" in name or path
- Handles both Android (DCIM/Screenshots, Pictures/Screenshots) and iOS
- Returns `List<File>` from discovered assets
- Falls back to `asset.originFile` if `asset.file` returns null

### PermissionService

Cross-platform permission management.

- `requestGalleryPermission()` → iOS: `Permission.photos`; Android: `Permission.photos` → fallback `Permission.storage`
- `hasGalleryPermission()` → Checks current grant status
- `openSettings()` → Opens system app settings
- Platform-aware (iOS vs Android) with debug logging

---

## 6. State Management & Providers

All state management uses **Riverpod** with the following provider types:

| Provider Type | Usage |
|--------------|-------|
| `FutureProvider` | Async data from database (screenshot list, stats, expenses) |
| `FutureProvider.family` | Parameterized async data (screenshot detail, search, category screenshots) |
| `StateProvider` | Simple mutable state (scanning status, search query) |
| `StateNotifierProvider` | Complex mutable state (settings) |
| `AsyncNotifierProvider` | Async actions (scan screenshots) |
| `Provider` | Synchronous dependencies (repository, category list) |

### Provider Map

| Provider | Type | Description |
|----------|------|-------------|
| `screenshotRepositoryProvider` | Provider | ScreenshotRepository singleton |
| `screenshotListProvider` | FutureProvider | All screenshots as ScreenshotItems |
| `screenshotDetailProvider(id)` | FutureProvider.family | Single screenshot by ID |
| `searchScreenshotsProvider(query)` | FutureProvider.family | Screenshot search results |
| `scanningProvider` | StateProvider | Boolean scanning state |
| `scanScreenshotsProvider` | AsyncNotifierProvider | Scan action with full pipeline |
| `deleteScreenshotProvider(id)` | FutureProvider.family | Delete screenshot + expenses |
| `homeStatsProvider` | FutureProvider | Aggregated dashboard stats |
| `expenseRepositoryProvider` | Provider | ExpenseRepository singleton |
| `expenseListProvider` | FutureProvider | All expenses |
| `expenseTotalProvider` | FutureProvider | Sum of all expense amounts |
| `expenseByCategoryProvider` | FutureProvider | Expense amounts grouped by category |
| `recentExpensesProvider` | FutureProvider | Latest 10 expenses |
| `expenseSearchQueryProvider` | StateProvider | Expense search text |
| `expenseSearchResultsProvider` | FutureProvider | Filtered expense results |
| `categoryListProvider` | Provider | Static list of 11 category names |
| `categoryCountsProvider` | FutureProvider | Screenshot count per category |
| `screenshotsByCategoryProvider(name)` | FutureProvider.family | Screenshots in a category |
| `searchQueryProvider` | StateProvider | Search input text |
| `searchResultsProvider` | FutureProvider | Full-text search results |
| `searchSuggestionsProvider` | Provider | 10 static suggestion chips |
| `settingsProvider` | StateNotifierProvider | AppSettings state + notifier |

---

## 7. Screens & Features

### 7.1 SplashScreen (`/`)

- Animated entrance with fade + scale (800ms)
- App icon container (cyan accent border, 10% opacity background)
- Tagline: "Your intelligent screenshot assistant"
- Circular progress indicator
- Auto-navigates after 2 seconds:
  - Permission granted → `/home`
  - Permission denied → `/permissions`

### 7.2 PermissionScreen (`/permissions`)

- Animated entrance (fade, 600ms)
- Contextual UI based on permission state:
  - First request: "Access Your Screenshots" with gallery icon
  - Permanently denied: "Permission Required" with lock icon
- Primary CTA: "Grant Permission"
- "Open Settings" link for permanent denial
- SnackBar feedback on denial with Settings action
- Uses `PermissionService.requestGalleryPermission()` with platform-specific handling

### 7.3 HomeDashboardScreen (`/home`)

**Purpose:** Answer "What useful information exists inside my screenshots?"

**Empty State:**
- Friendly illustration, subtitle explaining value proposition
- Full-width "Scan Screenshots" CTA button

**Populated State:**
- `SliverAppBar` with title + subtitle + search/settings buttons
- **Stats Grid** (2x2):
  - Screenshots count
  - Expenses count
  - Unprocessed count
  - Total spent (in rupees, green accent)
- **Quick Actions** row:
  - Scan (with loading state)
  - Categories → `/categories`
  - Expenses → `/expenses`
- **Recent Expenses** section (up to 5, with View All link)
- Pull-to-refresh
- Scanning banner with spinner during active scan

### 7.4 ScreenshotListScreen (`/screenshots`)

- AppBar with title + search icon
- FAB: "Scan" with loading state
- **Loading:** Centered spinner with message
- **Error:** Error icon + message + Retry button
- **Empty:** Friendly illustration + "Scan Now" button
- **Data:** 2-column grid (0.72 aspect ratio)
  - Rounded thumbnail with category color dot
  - Category label + relative date
- Pull-to-refresh

### 7.5 ScreenshotDetailScreen (`/screenshots/:id`)

- AppBar: "Details" with Share and Delete actions
- **Screenshot Preview:** Tappable card → opens `/viewer/:id`
- **Info Section:** Premium card with rows:
  - Category (colored dot + label)
  - Date
  - Expense indicator (if applicable)
- **Quick Actions:**
  - "Open Fullscreen" (outlined button)
  - "Share" (outlined button)
- **Extracted Text:** Full text in a card with comfortable line height (1.6)
- Share uses `share_plus` with image + text
- Delete with confirmation dialog; cascades to delete linked expenses

### 7.6 ScreenshotViewerScreen (`/viewer/:id`)

- Full-screen black background viewer
- **Single mode:** Standalone zoomable image
- **Gallery mode** (`?category=` query param): Swipeable `PageView`
- Features:
  - Pinch-to-zoom (1x–4x)
  - Double-tap to toggle zoom (2.5x)
  - Pan while zoomed
  - Auto-reset on zoom-to-1x
- Position counter badge (e.g., "3 / 15")
- Close button (top-left)
- Hero animation for smooth transitions

### 7.7 SearchScreen (`/search`)

- Inline search bar with Cancel button
- Auto-focused text field
- **Empty state:** 10 suggestion chips (Amazon order, Train ticket, UPI payment, etc.)
- **Results:** Premium cards with:
  - Thumbnail (88px wide)
  - Category dot + label
  - Highlighted text preview (matched term in primary color with opacity background)
  - Date
  - Chevron for tappable navigation
- Real-time search as user types
- "No Results" empty state with alternative suggestion

### 7.8 CategoriesScreen (`/categories`)

- AppBar: "Categories"
- 2-column grid (1.3 aspect ratio)
- 11 category cards with:
  - Accent-colored icon in container
  - Category name
  - Screenshot count (with pluralization)
- Tappable → `/categories/:name`

### 7.9 CategoryScreenshotsScreen (`/categories/:name`)

- AppBar with colored category dot + name
- Dense 3-column grid (0.72 aspect ratio)
- Small rounded thumbnails
- Tappable → viewer in gallery mode

### 7.10 ExpenseDashboardScreen (`/expenses`)

- AppBar: "Expenses"
- **Total Spend Card:** Wallet icon + formatted amount (green)
- **Categories Breakdown:** Premium card with:
  - Color-coded progress bars per category
  - Amount + percentage per category
  - Subtle dot + label design
- **Search Bar:** Inline search for expenses (searches merchant, category, description)
- **Results:**
  - Search active → "Search Results" section
  - No search → "Recent Expenses" section
- **Expense Cards:** Icon + merchant + category + date + amount (green)
- **Empty State:** "No Expenses Yet" with guidance to scan

### 7.11 SettingsScreen (`/settings`)

- Grouped sections in premium cards:
  - **Scanning:** Auto-scan toggle, OCR Wi-Fi toggle, Scan Interval picker
  - **Appearance:** Dark Mode toggle
  - **About:** Version (1.0.0), Database (Isar)
  - **Data:** Rescan All (with confirmation dialog)
- Scan interval picker: dialog with radio options (6, 12, 24, 48, 72 hours)
- Consistent icon + label + control pattern

---

## 8. Design System

### Color Palette

**Dark Mode (Primary):**

| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#0F172A` | Scaffold background |
| Surface | `#111827` | Sheet/dialog backgrounds |
| Card | `#1E293B` | Card backgrounds |
| Elevated | `#273449` | Elevated surfaces, input fills |
| Border | `#334155` | Borders |
| Primary | `#00E5FF` | Cyan accent — CTAs, highlights |
| Secondary | `#C084FC` | Purple accent |
| Success | `#10B981` | Green — expense amounts, success states |
| Warning | `#F59E0B` | Amber — warnings |
| Error | `#EF4444` | Red — errors, destructive actions |
| Text Primary | `#F8FAFC` | Primary text |
| Text Secondary | `#94A3B8` | Secondary/body text |
| Text Tertiary | `#64748B` | Captions, hints |

**Light Mode:** Derived from dark with inverted values (same structure, `light*` variants).

**Category Colors:**

| Category | Color | Hex |
|----------|-------|-----|
| Payments | Green | `#10B981` |
| UPI Receipts | Teal | `#14B8A6` |
| Shopping | Amber | `#F59E0B` |
| Travel Tickets | Blue | `#3B82F6` |
| Bills | Red | `#EF4444` |
| Documents | Purple | `#8B5CF6` |
| OTP Screenshots | Orange | `#F97316` |
| Addresses | Pink | `#EC4899` |
| Notes | Indigo | `#6366F1` |
| Social Media | Cyan | `#06B6D4` |
| Other | Gray | `#64748B` |

### Typography

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayLarge` | 34 | 700 | Hero numbers (unused) |
| `displayMedium` | 28 | 700 | Amount displays |
| `displaySmall` | 24 | 700 | Stat values |
| `headlineLarge` | 22 | 600 | (unused) |
| `headlineMedium` | 20 | 600 | Empty state titles |
| `headlineSmall` | 18 | 600 | Section titles |
| `titleLarge` | 17 | 600 | (unused) |
| `titleMedium` | 15 | 600 | Section headers |
| `titleSmall` | 14 | 600 | Card titles |
| `bodyLarge` | 16 | 400 | Body text |
| `bodyMedium` | 14 | 400 | Default body |
| `bodySmall` | 13 | 400 | Secondary text |
| `labelLarge` | 14 | 500 | Button labels |
| `labelMedium` | 12 | 500 | Chip labels |
| `labelSmall` | 11 | 500 | Captions |

### Spacing (12px grid)

| Token | Pixels |
|-------|--------|
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 20 |
| `xxl` | 24 |
| `xxxl` | 32 |
| `huge` | 40 |
| `massive` | 48 |

### Component Library (`lib/core/components/`)

| Component | Description |
|-----------|-------------|
| `SbCard` | Premium card with ink effect, optional padding/color/onTap |
| `SbCardHeader` | Card header row with icon + title + subtitle + trailing |
| `SbStatCard` | Dashboard stat: icon + value + label |
| `SbSectionHeader` | Section title with optional "View All" |
| `SbEmptyState` | Centered icon + title + subtitle + action |
| `SbErrorState` | Error display with optional retry |
| `SbLoading` | Centered spinner with optional message |
| `SbChip` | Animated chip with optional icon + color + selected state |
| `SbTab` | Tab label with optional count badge |

### Theme Extension

`ScreenshotBrainThemeExtension` provides custom theme properties via `context.sb`:
- `sb.background`, `sb.surface`, `sb.card`, `sb.elevated`
- `sb.border`, `sb.borderLight`
- `sb.success`, `sb.successContainer`, `sb.warning`, `sb.warningContainer`
- `sb.textPrimary`, `sb.textSecondary`, `sb.textTertiary`, `sb.textInverse`
- `sb.primaryDim`, `sb.secondaryDim`
- `sb.shimmerBase`, `sb.shimmerHighlight`

---

## 9. Scan Pipeline

When the user taps "Scan" (or auto-scan triggers), the following pipeline executes:

```
1. ScreenshotScannerService.scanScreenshots()
   │
   ├── Request photo_manager permission
   ├── Discover all image albums
   ├── Filter for "screenshot" albums
   └── Return List<File>
   │
2. For each file:
   │
   ├── Check for duplicate (by filePath in Isar)
   ├── Create ScreenshotModel → save to Isar
   │
   ├── OcrService.extractTextFromFile()
   │   └── Google ML Kit processes image → returns String
   │
   ├── Update model: extractedText, isProcessed = true
   │
   ├── CategorizationService.categorize(text)
   │   └── Keyword scoring → returns category name
   │
   ├── Update model: category = result
   │
   ├── CategorizationService.isExpense(text)
   │   └── If true:
   │       ├── Mark screenshot as expense
   │       ├── ExpenseExtractionService.extractExpense()
   │       │   ├── Extract amount (regex)
   │       │   ├── Extract merchant (regex)
   │       │   ├── Extract date (regex)
   │       │   └── Determine expense category
   │       └── Save ExpenseModel to Isar
   │
3. Invalidate providers (refresh UI)
4. Dispose OCR service
```

---

## 10. Categorization Engine

Keyword-based scoring system with 11 categories:

| Category | Sample Keywords |
|----------|----------------|
| **Payments** | payment, paid, transaction, debit, credit, bank, account |
| **UPI Receipts** | upi, gpay, google pay, phonepe, paytm, bhim, upi ref, trxid |
| **Shopping** | amazon, flipkart, myntra, order, invoice, zomato, swiggy, blinkit |
| **Travel Tickets** | train, railway, irctc, flight, boarding pass, ticket, pnr, uber, ola |
| **Bills** | bill, electricity, gas, mobile bill, recharge, broadband, insurance |
| **Documents** | aadhar, pan card, passport, license, certificate, marksheet |
| **OTP Screenshots** | otp, one time password, verification code, login code |
| **Addresses** | address, location, map, delivery address, shipping address |
| **Notes** | note, reminder, todo, task, list, idea, important |
| **Social Media** | instagram, facebook, twitter, whatsapp, telegram, snapchat |
| **Other** | (fallback when no keywords match) |

**Scoring:** Each keyword match adds `keyword.length` points. The category with the highest cumulative score wins.

---

## 11. Expense Detection & Extraction

### Detection

A screenshot is flagged as an expense if the extracted text contains any of:
```
paid, payment, debit, credit, amount, rs, ₹, $, total, invoice, bill, receipt,
transaction, purchase, order, paid to, sent, transferred, upi, gpay, phonepe, paytm
```

### Structured Extraction

**Amount Patterns:**
- `Rs. 1,234.56`, `INR 1,234`, `₹1,234.00`
- `1,234.56 Rs`, `Total: ₹500`
- `$29.99`, `50 USD`

**Merchant Patterns:**
- "paid to XYZ", "sent to XYZ", "payment to XYZ"
- "from XYZ", "via XYZ"

**Date Patterns:**
- `dd/mm/yyyy`, `dd-mm-yy`
- `dd Mon yyyy` (e.g., "15 Jan 2024")
- `Mon dd, yyyy` (e.g., "Jan 15, 2024")

**Expense Sub-Categories:**

| Sub-Category | Keywords |
|-------------|----------|
| Food | grocery, food, restaurant, zomato, swiggy |
| Travel | travel, flight, train, bus, cab, uber, ola, hotel |
| Shopping | shopping, amazon, flipkart, myntra, cloth |
| Bills | bill, electricity, water, gas, mobile, recharge, broadband |
| Healthcare | medicine, hospital, doctor, health, pharmacy |
| Entertainment | entertainment, movie, netflix, spotify, game |
| Other | (fallback) |

---

## 12. Settings & Configuration

`AppSettings` model with defaults:

| Setting | Default | Type | UI Control |
|---------|---------|------|------------|
| `autoScanEnabled` | `true` | bool | Switch |
| `darkModeEnabled` | `false` | bool | Switch |
| `ocrOnWifiOnly` | `false` | bool | Switch |
| `scanIntervalHours` | `24` | int | Radio picker (6/12/24/48/72) |

Managed by `SettingsNotifier` (StateNotifier) with `copyWith` pattern.

**Other settings:**
- **Rescan All:** Confirmation dialog (data management, no action currently wired)
- **Version:** 1.0.0
- **Database:** Isar Local Database (informational)

---

## 13. Permissions Flow

**iOS:**
- Uses `Permission.photos`
- Handles `.granted` and `.limited` as success
- No fallback needed

**Android:**
- Primary: `Permission.photos` (API 33+ → `READ_MEDIA_IMAGES`)
- Fallback: `Permission.storage` (older API → `READ_EXTERNAL_STORAGE`)
- Handles `.permanentlyDenied` with Settings link

**Flow:**
```
App Launch → SplashScreen → hasGalleryPermission()?
                              ├── Yes → /home
                              └── No → /permissions → requestGalleryPermission()?
                                                        ├── Granted → /home
                                                        └── Denied → Show SnackBar + Settings link
                                                                      └── Permanently Denied → Update UI
```

---

## Appendix: File Inventory

### Dart Files (41 total)

| # | File Path | Type |
|---|-----------|------|
| 1 | `lib/main.dart` | Entry point |
| 2 | `lib/app.dart` | App widget |
| 3 | `lib/core/router/app_router.dart` | Routes |
| 4 | `lib/core/theme/app_colors.dart` | Colors |
| 5 | `lib/core/theme/app_theme.dart` | Theme |
| 6 | `lib/core/theme/theme_extensions.dart` | Theme extension |
| 7 | `lib/core/design/tokens.dart` | Design tokens |
| 8 | `lib/core/components/sb_card.dart` | Card component |
| 9 | `lib/core/components/sb_empty_state.dart` | Empty state component |
| 10 | `lib/core/components/sb_error_state.dart` | Error state component |
| 11 | `lib/core/components/sb_loading.dart` | Loading component |
| 12 | `lib/core/components/sb_stat_card.dart` | Stat card component |
| 13 | `lib/core/components/sb_section_header.dart` | Section header component |
| 14 | `lib/core/components/sb_chip.dart` | Chip component |
| 15 | `lib/core/components/sb_tab_bar.dart` | Tab component |
| 16 | `lib/core/widgets/empty_state_widget.dart` | Legacy wrapper |
| 17 | `lib/core/widgets/error_widget.dart` | Legacy wrapper |
| 18 | `lib/core/widgets/loading_widget.dart` | Legacy wrapper |
| 19 | `lib/core/utils/constants.dart` | Constants |
| 20 | `lib/core/utils/extensions.dart` | Extensions |
| 21 | `lib/features/home/providers/home_provider.dart` | Provider |
| 22 | `lib/features/home/screens/home_dashboard_screen.dart` | Screen |
| 23 | `lib/features/screenshots/providers/screenshot_provider.dart` | Provider |
| 24 | `lib/features/screenshots/models/screenshot_item.dart` | Model |
| 25 | `lib/features/screenshots/repositories/screenshot_repository.dart` | Repository |
| 26 | `lib/features/screenshots/screens/screenshot_list_screen.dart` | Screen |
| 27 | `lib/features/screenshots/screens/screenshot_detail_screen.dart` | Screen |
| 28 | `lib/features/screenshots/screens/screenshot_viewer_screen.dart` | Screen |
| 29 | `lib/features/categories/providers/category_provider.dart` | Provider |
| 30 | `lib/features/categories/screens/categories_screen.dart` | Screen |
| 31 | `lib/features/categories/screens/category_screenshots_screen.dart` | Screen |
| 32 | `lib/features/search/providers/search_provider.dart` | Provider |
| 33 | `lib/features/search/screens/search_screen.dart` | Screen |
| 34 | `lib/features/expenses/providers/expense_provider.dart` | Provider |
| 35 | `lib/features/expenses/models/expense_item.dart` | Model |
| 36 | `lib/features/expenses/repositories/expense_repository.dart` | Repository |
| 37 | `lib/features/expenses/screens/expense_dashboard_screen.dart` | Screen |
| 38 | `lib/features/settings/providers/settings_provider.dart` | Provider |
| 39 | `lib/features/settings/screens/settings_screen.dart` | Screen |
| 40 | `lib/features/splash/screens/splash_screen.dart` | Screen |
| 41 | `lib/features/permissions/screens/permission_screen.dart` | Screen |
| 42 | `lib/services/database_service.dart` | Service |
| 43 | `lib/services/ocr_service.dart` | Service |
| 44 | `lib/services/categorization_service.dart` | Service |
| 45 | `lib/services/expense_extraction_service.dart` | Service |
| 46 | `lib/services/screenshot_scanner_service.dart` | Service |
| 47 | `lib/services/permission_service.dart` | Service |
| 48 | `lib/shared/models/screenshot_model.dart` | Isar model |
| 49 | `lib/shared/models/screenshot_model.g.dart` | Generated |
| 50 | `lib/shared/models/expense_model.dart` | Isar model |
| 51 | `lib/shared/models/expense_model.g.dart` | Generated |
| 52 | `test/widget_test.dart` | Test |

### Asset Files

| File | Purpose |
|------|---------|
| `assets/app-logo.png` | App logo asset |
| `web/favicon.png` | Web favicon |
| `web/icons/Icon-192.png` | PWA icon |
| `web/icons/Icon-512.png` | PWA icon |
| `web/icons/Icon-maskable-192.png` | Maskable PWA icon |
| `web/icons/Icon-maskable-512.png` | Maskable PWA icon |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | Android launcher icons |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | iOS app icons |
| `windows/runner/resources/app_icon.ico` | Windows app icon |

---

*Document generated from codebase analysis. All feature descriptions reflect the actual implementation as of version 1.0.0+1.*
