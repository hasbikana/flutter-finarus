# Finarus — ERD & Flutter Integration Guide

> **App Name:** Finarus | **DB:** MySQL `finarus_db` | **Auth:** Laravel Sanctum (token + session)

---

## 1. Visual ERD

```
┌─────────────────────────────────────────────────────────────┐
│                         users                               │
│  id, name, email, password, password_set_at, ...           │
└──────┬──────┬──────┬──────┬──────┬──────┬───────────────────┘
       │      │      │      │      │      │
       │      │      │      │      │      └── (1) user_settings
       │      │      │      │      │              email_notifications,
       │      │      │      │      │              budget_alerts,
       │      │      │      │      │              theme, email_fetch_enabled
       │      │      │      │      │
       │      │      │      │      └── (N) user_oauth_tokens
       │      │      │      │              provider, access_token,
       │      │      │      │              refresh_token, expires_at, email
       │      │      │      │
       │      │      │      └── (N) accounts
       │      │      │              name, provider, type (cash/ewallet/bank/credit_card),
       │      │      │              account_number, balance, logo
       │      │      │
       │      │      └── (N) saving_goals
       │      │              name, target_amount, current_amount,
       │      │              deadline, icon, image
       │      │              * progress() = min(100, current/target)
       │      │              * remaining() = max(0, target - current)
       │      │
       │      └── (N) budgets
       │              category_id, amount, month, year
       │              UNIQUE(user_id, category_id, month, year)
       │              * spent() = sum transactions for category/month
       │              * progress() = min(100, spent/amount)
       │              * is_over_budget() = spent > amount
       │
       └── (N) categories
                name, type (income/expense/both), icon, color
                │
                └── (N) transactions ──────────────────┐
                         type (income/expense),         │
                         amount, description,           │
                         transaction_date,              │
                         email_message_id, source       │
                         category_id (FK cascade) ──────┘
                         account_id (FK set null)
                         saving_goal_id (FK set null)
```

---

## 2. Table Definitions

### 2.1 `users`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| name | varchar(255) | NOT | — | |
| email | varchar(255) | NOT | — | UNIQUE |
| email_verified_at | timestamp | YES | NULL | |
| password | varchar(255) | NOT | — | hashed |
| password_set_at | timestamp | YES | NULL | NULL = Google user (no password set yet) |
| remember_token | varchar(100) | YES | NULL | |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

**Flutter model:**
```dart
class User {
  final int id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final DateTime? passwordSetAt; // null = Google-only
  final DateTime createdAt;
}
```

---

### 2.2 `categories`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| user_id | bigint FK | NOT | — | → users(id) ON DELETE CASCADE |
| name | varchar(255) | NOT | — | |
| type | ENUM | NOT | 'both' | income, expense, both |
| icon | varchar(255) | YES | NULL | Emoji |
| color | varchar(255) | YES | NULL | Hex e.g. #FF5722 |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

```dart
class Category {
  final int id;
  final String name;
  final String type; // 'income' | 'expense' | 'both'
  final String? icon;
  final String? color;
  final int transactionsCount; // withCount
}
```

---

### 2.3 `accounts`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| user_id | bigint FK | NOT | — | → users(id) ON DELETE CASCADE |
| name | varchar(255) | NOT | — | e.g. "Rekening Utama" |
| provider | varchar(255) | NOT | — | e.g. "BCA", "GoPay" |
| type | ENUM | NOT | 'bank' | cash, ewallet, bank, credit_card |
| account_number | varchar(255) | YES | NULL | |
| balance | decimal(15,2) | NOT | 0.00 | Auto-recalculated by TransactionService |
| logo | varchar(255) | YES | NULL | e.g. "bca", "gopay" |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

```dart
class Account {
  final int id;
  final String name;
  final String provider;
  final String type; // 'cash' | 'ewallet' | 'bank' | 'credit_card'
  final String? accountNumber;
  final double balance;
  final String? logo;
  String get logoPath => logo != null ? '/logos/$logo.png' : null;
}
```

**Important:** Cash account is auto-created per user (type=cash, name="Cash / Dompet"). Balance recalculated on every transaction create/update/delete via `TransactionService`.

---

### 2.4 `transactions` (core)

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| user_id | bigint FK | NOT | — | → users(id) ON DELETE CASCADE |
| category_id | bigint FK | NOT | — | → categories(id) ON DELETE CASCADE |
| account_id | bigint FK | YES | NULL | → accounts(id) ON DELETE SET NULL |
| saving_goal_id | bigint FK | YES | NULL | → saving_goals(id) ON DELETE SET NULL |
| type | ENUM | NOT | — | income, expense |
| amount | decimal(15,2) | NOT | — | |
| description | varchar(255) | YES | NULL | |
| email_message_id | varchar(255) | YES | NULL | UNIQUE, for dedup from Gmail |
| source | varchar(255) | YES | NULL | 'email', 'manual', 'import' |
| transaction_date | date | NOT | — | |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

```dart
class Transaction {
  final int id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final String? emailMessageId;
  final String? source;
  final int categoryId;
  final int? accountId;
  final int? savingGoalId;
  // Relationships (loaded via API Resource)
  final Category? category;
  final Account? account;
  final SavingGoal? savingGoal;
}
```

---

### 2.5 `saving_goals`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| user_id | bigint FK | NOT | — | → users(id) ON DELETE CASCADE |
| name | varchar(255) | NOT | — | |
| target_amount | decimal(15,2) | NOT | — | |
| current_amount | decimal(15,2) | NOT | 0.00 | Auto-incremented by TransactionService |
| deadline | date | YES | NULL | |
| icon | varchar(255) | YES | NULL | Emoji |
| image | varchar(255) | YES | NULL | Path in storage/uploads/ |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

**Computed (not in DB):**
```dart
double get progress => targetAmount > 0
    ? min(100, (currentAmount / targetAmount * 100).roundToDouble())
    : 0;
double get remaining => max(0, targetAmount - currentAmount);
```

**How current_amount updates:**
1. User clicks "+ Tambah Dana" on a goal → creates expense transaction with `saving_goal_id`
2. `TransactionService.createTransaction()` detects `saving_goal_id` + type=expense → auto-increments `current_amount`

---

### 2.6 `budgets`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| user_id | bigint FK | NOT | — | → users(id) ON DELETE CASCADE |
| category_id | bigint FK | NOT | — | → categories(id) ON DELETE CASCADE |
| amount | decimal(15,2) | NOT | — | Max budget |
| month | smallint | NOT | — | 1–12 |
| year | smallint | NOT | — | |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

**UNIQUE(user_id, category_id, month, year)** — one budget per category per month.

**Computed (not in DB):**
```dart
double get spent => // sum of expense transactions for this category/month/year
double get progress => amount > 0 ? min(100, (spent / amount * 100)) : 0;
bool get isOverBudget => spent > amount;
```

---

### 2.7 `user_settings`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| user_id | bigint FK | NOT | — | → users(id) ON DELETE CASCADE, UNIQUE |
| email_notifications | boolean | NOT | true | |
| budget_alerts | boolean | NOT | true | |
| theme | ENUM | NOT | 'light' | light, dark |
| email_fetch_enabled | boolean | NOT | false | Gmail auto-import toggle |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

```dart
class UserSettings {
  final bool emailNotifications;
  final bool budgetAlerts;
  final String theme; // 'light' | 'dark'
  final bool emailFetchEnabled;
}
```

---

### 2.8 `user_oauth_tokens`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint PK | — | auto-inc | |
| user_id | bigint FK | NOT | — | → users(id) ON DELETE CASCADE |
| provider | varchar(255) | NOT | 'google' | |
| access_token | text | NOT | — | |
| refresh_token | text | YES | NULL | |
| expires_at | timestamp | YES | NULL | |
| email | varchar(255) | YES | NULL | Connected Gmail address |
| scopes | text | YES | NULL | |
| created_at | timestamp | YES | NULL | |
| updated_at | timestamp | YES | NULL | |

**UNIQUE(user_id, provider)** — one token per provider per user.

---

## 3. Color Theme (Flutter ThemeData)

### Light Mode

```dart
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: const Color(0xFF2563EB), // primary
  scaffoldBackgroundColor: const Color(0xFFFFFFFF), // background
  cardColor: const Color(0xFFFFFFFF), // card
);

// Semantic colors:
// background:   #FFFFFF
// foreground:   #020617
// card:         #FFFFFF
// primary:      #2563EB
// primary-fg:   #F8FAFC
// secondary:    #F1F5F9
// muted:        #F1F5F9
// muted-fg:     #64748B
// destructive:  #EF4444
// border:       #E2E8F0
// ring:         #2563EB
```

### Dark Mode

```dart
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: const Color(0xFF3B82F6), // primary (slightly lighter)
  scaffoldBackgroundColor: const Color(0xFF020617), // background
  cardColor: const Color(0xFF020A1C), // card
);

// Semantic colors:
// background:   #020617
// foreground:   #F8FAFC
// card:         #020A1C
// primary:      #3B82F6
// primary-fg:   #0F172A
// secondary:    #1E293B
// muted:        #1E293B
// muted-fg:     #94A3B8
// destructive:  #7F1D1D
// border:       #1E293B
// ring:         #2563EB
```

### Chart Colors (used in Laporan)

```dart
const chartBlue   = Color(0xFF2563EB);
const chartGreen  = Color(0xFF16A34A);
const chartRed    = Color(0xFFEF4444);
const chartOrange = Color(0xFFF97316);
const chartPurple = Color(0xFF8B5CF6);
const chartYellow = Color(0xFFEAB308);
```

---

## 4. Auth Flow for Flutter

```
┌─────────────────────────────────────────────────────┐
│                  Flutter App                        │
│                                                     │
│  1. POST /api/auth/login                            │
│     Body: { email, password }                       │
│     → { token: "1|abc..." }                         │
│                                                     │
│  2. Store token in secure storage                   │
│                                                     │
│  3. All subsequent API calls:                       │
│     Header: Authorization: Bearer 1|abc...           │
│     Header: Accept: application/json                 │
│                                                     │
│  4. POST /api/auth/register                         │
│     Body: { name, email, password, password_confirmation }│
│     → { token: "2|xyz..." }                         │
│                                                     │
│  5. POST /api/auth/logout                           │
│     → token deleted from DB                         │
└─────────────────────────────────────────────────────┘
```

**Google OAuth on Flutter:**
- Flutter handles Google Sign-In (`google_sign_in` package)
- Get `idToken` from Google
- Currently NOT implemented on backend — you'd need to add `POST /api/auth/google` endpoint accepting the Google idToken

---

## 5. API Endpoints (Flutter uses ALL of these)

### Auth (No Token)
| Method | Endpoint | Body |
|--------|----------|------|
| POST | `/api/auth/register` | `{name, email, password, password_confirmation}` |
| POST | `/api/auth/login` | `{email, password}` |

### Auth (Token Required)
| Method | Endpoint | Notes |
|--------|----------|-------|
| POST | `/api/logout` | Delete current token |
| GET | `/api/me` | Current user |

### Dashboard
| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/api/dashboard` | `{balance, total_income, total_expense, active_saving_goals, recent_transactions[], budget_progress[]}` |

### CRUD — Categories
| Method | Endpoint |
|--------|----------|
| GET | `/api/categories` |
| POST | `/api/categories` |
| GET | `/api/categories/{id}` |
| PUT | `/api/categories/{id}` |
| DELETE | `/api/categories/{id}` |

### CRUD — Transactions
| Method | Endpoint | Query Params |
|--------|----------|-------------|
| GET | `/api/transactions` | `?type=&category_id=&account_id=&date_from=&date_to=&search=&per_page=` |
| POST | `/api/transactions` | `{category_id, account_id, type, amount, description, transaction_date}` |
| GET | `/api/transactions/{id}` | |
| PUT | `/api/transactions/{id}` | |
| DELETE | `/api/transactions/{id}` | |

### CRUD — Budgets
| Method | Endpoint | Query Params |
|--------|----------|-------------|
| GET | `/api/budgets` | `?month=&year=` |
| POST | `/api/budgets` | `{category_id, amount, month, year}` |
| PUT | `/api/budgets/{id}` | |
| DELETE | `/api/budgets/{id}` | |

### CRUD — Saving Goals
| Method | Endpoint |
|--------|----------|
| GET | `/api/saving-goals` |
| POST | `/api/saving-goals` |
| PUT | `/api/saving-goals/{id}` |
| DELETE | `/api/saving-goals/{id}` |

### CRUD — Accounts
| Method | Endpoint |
|--------|----------|
| GET | `/api/accounts` | (includes meta.total_balance, meta.total_accounts) |
| POST | `/api/accounts` | `{name, provider, type, account_number?, balance?, logo?}` |
| PUT | `/api/accounts/{id}` | |
| DELETE | `/api/accounts/{id}` | (returns 422 if has transactions) |

### Reports
| Method | Endpoint | Query |
|--------|----------|-------|
| GET | `/api/reports/monthly` | `?month=&year=` |
| GET | `/api/reports/categories` | `?type=expense&month=&year=` |
| GET | `/api/reports/trend` | `?year=` |
| GET | `/api/reports/export` | `?format=csv|pdf&month=&year=` |

### Settings
| Method | Endpoint |
|--------|----------|
| GET | `/api/settings` |
| PUT | `/api/settings` |
| PUT | `/api/settings/password` |

### OAuth
| Method | Endpoint |
|--------|----------|
| GET | `/api/oauth/status` |
| DELETE | `/api/oauth/google` |

### Upload
| Method | Endpoint |
|--------|----------|
| POST | `/api/upload` | (multipart: file, max 2MB, jpg/png/gif/webp) |

---

## 6. Flutter Data Classes (Example)

```dart
// Minimal data classes matching API JSON

class TransactionResponse {
  final List<Transaction> data;
  final int currentPage;
  final int lastPage;
  final int total;
}

class DashboardResponse {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final int activeSavingGoals;
  final List<Transaction> recentTransactions;
  final List<Budget> budgetProgress;
}

class AccountListResponse {
  final List<Account> data;
  final double totalBalance;
  final int totalAccounts;
}

class MonthlyReport {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int month;
  final int year;
}

class TrendReport {
  final int year;
  final List<TrendPoint> trend;
}

class TrendPoint {
  final int month;
  final String monthName;
  final double income;
  final double expense;
  final double net;
}

class CategoryReport {
  final String type;
  final int month;
  final int year;
  final List<CategoryTotal> categories;
}

class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double total;
}
```

---

## 7. Key Business Logic (Flutter Must Replicate)

### Account Balance Rule
```
balance = SUM(income transactions) - SUM(expense transactions)
```
Always recalculated, never manually set after creation.

### Saving Goal Progress
```
progress = min(100, current_amount / target_amount × 100)
```
`current_amount` increments when an expense transaction is linked to the goal.

### Budget Spent
```
spent = SUM(expense transactions for that category + month + year)
progress = min(100, spent / amount × 100)
is_over_budget = spent > amount
```

### Cash Account
- Auto-created for every user (type=cash, name="Cash / Dompet")
- Hidden from dompet-digital listing
- Balance auto-managed via transactions

---

> **Created:** June 2026 | **Environment:** Laravel 11 + MySQL 8.4 + Sanctum | **Flutter Target:** Flutter 3.x with Material 3
