# Finarus API Reference — Flutter Mobile App

Base URL: `https://finarus.app/api` (sesuaikan)

Auth: **Bearer token** via Laravel Sanctum (`Authorization: Bearer <token>`)

---

## Daftar Isi

1. [State Management — Data Flow](#state-management--data-flow)
2. [Autentikasi](#autentikasi)
3. [Dashboard](#dashboard)
4. [Categories](#categories)
5. [Accounts](#accounts)
6. [Transactions](#transactions)
7. [Pending Transactions](#pending-transactions)
8. [Pending Notifications (Notif HP & OCR)](#pending-notifications)
9. [Budgets](#budgets)
10. [Saving Goals](#saving-goals)
11. [Reports](#reports)
12. [Settings](#settings)
13. [OAuth / Google](#oauth--google)
14. [Alerts](#alerts)
15. [Upload](#upload)
16. [Error Response Format](#error-response-format)
17. [Complete Endpoint List](#complete-endpoint-list)
18. [Catatan Penting](#catatan-penting)

---

## State Management — Data Flow

### Model-View-ViewModel (MVVM) Pattern

```
[View / Screen] <--> [ViewModel / Cubit] <--> [Repository] <--> [ApiService] <--> [Laravel API]
```

### Recommended State Architecture (Bloc/Cubit per fitur)

```
lib/
├── core/
│   ├── api/
│   │   ├── api_service.dart          # HTTP client (Dio)
│   │   ├── api_exceptions.dart       # Error handling
│   │   └── api_interceptor.dart      # Bearer token interceptor
│   ├── storage/
│   │   └── secure_storage.dart       # Token storage
│   └── models/                       # Data models (mirip Eloquent)
│       ├── user.dart
│       ├── transaction.dart
│       ├── category.dart
│       ├── account.dart
│       ├── budget.dart
│       ├── saving_goal.dart
│       ├── setting.dart
│       └── pending_notification.dart
├── features/
│   ├── auth/
│   │   ├── cubit/auth_cubit.dart     # Auth state
│   │   ├── screens/
│   │   └── repositories/
│   ├── dashboard/
│   │   ├── cubit/dashboard_cubit.dart
│   │   └── screens/
│   ├── transactions/
│   │   ├── cubit/transaction_cubit.dart
│   │   └── screens/
│   ├── categories/
│   ├── accounts/
│   ├── budgets/
│   ├── saving_goals/
│   ├── reports/
│   ├── notifications/
│   ├── settings/
│   └── google_oauth/
└── main.dart
```

### Global State (harus persist after login)

| Key | Type | Source | Description |
|-----|------|--------|-------------|
| `token` | `String` | Login/register | Bearer token, simpan di `flutter_secure_storage` |
| `user` | `User` | `GET /api/me` | Data user login |
| `settings` | `UserSetting` | `GET /api/settings` | Preferensi user |

### Local State (per screen, refresh setiap screen dibuka)

| Screen | Data | Endpoint |
|--------|------|----------|
| Dashboard | `balance`, `total_income`, `total_expense`, `recent_transactions`, `budget_progress`, `pending_count` | `GET /api/dashboard` |
| Transactions list | Paginated transactions | `GET /api/transactions` |
| Budgets | Budgets with computed `spent`, `progress` | `GET /api/budgets` |
| Reports | Monthly/category/trend summaries | `GET /api/reports/*` |

### Auth Flow

```dart
// 1. Cek saved token di secure storage
// 2. Jika ada, GET /api/me untuk validasi
// 3. Jika valid -> ke Home
// 4. Jika 401 -> hapus token -> ke Login

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;
}
```

---

## Autentikasi

### Register

```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Response `201`:**
```json
{
  "message": "Registrasi berhasil",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "email_verified_at": null,
    "password_set_at": null,
    "created_at": "2026-06-23T12:00:00.000000Z",
    "updated_at": "2026-06-23T12:00:00.000000Z"
  },
  "token": "1|abc123..."
}
```

### Login Email/Password

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response `200`:**
```json
{
  "message": "Login berhasil",
  "user": { ... },
  "token": "1|abc123..."
}
```

**Error `422`:**
```json
{
  "message": "Kredensial yang diberikan tidak cocok.",
  "errors": {
    "email": ["Kredensial yang diberikan tidak cocok."]
  }
}
```

### Google Login (Mobile — ID Token)

Backend verifikasi `id_token` dari Google Sign-In. Untuk Flutter, gunakan package `google_sign_in`.

```http
POST /api/auth/google
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

**Flutter Implementation:**
```dart
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

Future<void> signInWithGoogle() async {
  final GoogleSignInAccount? account = await _googleSignIn.signIn();
  final GoogleSignInAuthentication auth = await account!.authentication;

  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id_token': auth.idToken}),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    final data = jsonDecode(response.body);
    await SecureStorage.saveToken(data['token']);
    // data['user'], data['token']
  }
}
```

**Response `200`** (user sudah ada):
```json
{
  "message": "Login berhasil",
  "user": { "id": 1, "name": "John", "email": "john@gmail.com", ... },
  "token": "1|abc123..."
}
```

**Response `201`** (user baru — auto-register + default akun Cash / Dompet):
```json
{
  "message": "Registrasi berhasil",
  "user": { "id": 2, "name": "John", "email": "john@gmail.com", ... },
  "token": "2|def456..."
}
```

### Logout

```http
POST /api/logout
Authorization: Bearer <token>
```

```json
{ "message": "Logout berhasil" }
```

> Hapus token dari `flutter_secure_storage` setelah logout.

### Current User

```http
GET /api/me
Authorization: Bearer <token>
```

**Response `200`:** Langsung return object User (tanpa wrapper):
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "email_verified_at": null,
  "password_set_at": null,
  "created_at": "2026-06-23T12:00:00.000000Z",
  "updated_at": "2026-06-23T12:00:00.000000Z"
}
```

---

## Dashboard

```http
GET /api/dashboard
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "balance": 5000000.00,
  "total_income": 3000000.00,
  "total_expense": 1500000.00,
  "active_saving_goals": 2,
  "recent_transactions": [
    {
      "id": 1,
      "type": "expense",
      "amount": 50000.00,
      "description": "Nasi goreng",
      "transaction_date": "2026-06-23",
      "category": { "id": 1, "name": "Makanan", "icon": "utensils", "color": "#ef4444" },
      "account": { "id": 1, "name": "Cash / Dompet" },
      "is_pending": false,
      "pending_source": null,
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "budget_progress": [
    {
      "id": 1,
      "amount": 1000000.00,
      "spent": 500000.00,
      "progress": 50.0,
      "is_over_budget": false,
      "month": 6,
      "year": 2026,
      "category": { "id": 1, "name": "Makanan", "icon": "utensils", "color": "#ef4444" }
    }
  ],
  "pending_count": 3
}
```

---

## Categories

### List Categories

```http
GET /api/categories?type=expense&search=makan
Authorization: Bearer <token>
```

Query params:
- `type` (optional): `income`, `expense`, `both`
- `search` (optional): text search by name

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Makanan",
      "type": "expense",
      "icon": "utensils",
      "color": "#ef4444",
      "transactions_count": 15,
      "created_at": "2026-06-23T12:00:00.000000Z",
      "updated_at": "2026-06-23T12:00:00.000000Z"
    }
  ]
}
```

### Create Category

```http
POST /api/categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Makanan",
  "type": "expense|income|both",
  "icon": "utensils",
  "color": "#ef4444"
}
```

Validation rules:
| Field | Rules |
|-------|-------|
| `name` | required, string, max:255 |
| `type` | required, in:income,expense,both |
| `icon` | nullable, string, max:50 |
| `color` | nullable, string, max:50 |

### Show / Update / Delete

```http
GET /api/categories/{id}
PUT /api/categories/{id}
DELETE /api/categories/{id}
```

---

## Accounts

### List Accounts

```http
GET /api/accounts
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Cash / Dompet",
      "provider": "Cash",
      "type": "cash",
      "account_number": null,
      "balance": 5000000.00,
      "logo": null,
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "meta": {
    "total_balance": 5000000.00,
    "total_accounts": 1
  }
}
```

### Create Account

```http
POST /api/accounts
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "BCA",
  "provider": "Bank BCA",
  "type": "bank|cash|ewallet|credit_card",
  "account_number": "1234567890",
  "balance": 5000000.00,
  "logo": null
}
```

Validation rules:
| Field | Rules |
|-------|-------|
| `name` | required, string, max:255 |
| `provider` | required, string, max:255 |
| `type` | required, in:cash,ewallet,bank,credit_card |
| `account_number` | nullable, string, max:100 |
| `balance` | nullable, numeric, min:0 |
| `logo` | nullable, string, max:100 |

### Show / Update / Delete

```http
GET /api/accounts/{id}
PUT /api/accounts/{id}
DELETE /api/accounts/{id}
```

> **Note:** Delete akan 422 error jika account masih punya transaksi.

---

## Transactions

### List Transactions

```http
GET /api/transactions?page=1&per_page=20&type=expense&category_id=1&account_id=1&date_from=2026-01-01&date_to=2026-06-30&search=nasi
Authorization: Bearer <token>
```

Query params:
- `page`, `per_page` — pagination (default: 15)
- `type` — `income` / `expense`
- `category_id` — filter by category
- `account_id` — filter by account
- `date_from`, `date_to` — date range (format: Y-m-d)
- `search` — text search in description

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "type": "expense",
      "amount": 50000.00,
      "description": "Nasi goreng",
      "transaction_date": "2026-06-23",
      "source": "manual",
      "is_pending": false,
      "pending_source": null,
      "category": { "id": 1, "name": "Makanan", "icon": "utensils", "color": "#ef4444" },
      "account": { "id": 1, "name": "Cash / Dompet", "type": "cash" },
      "saving_goal": null,
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 100
  }
}
```

### Create Transaction

```http
POST /api/transactions
Authorization: Bearer <token>
Content-Type: application/json

{
  "category_id": 1,
  "account_id": 1,
  "saving_goal_id": null,
  "type": "expense",
  "amount": 50000,
  "description": "Nasi goreng",
  "transaction_date": "2026-06-23",
  "pending_source": "manual"
}
```

Validation rules:
| Field | Rules |
|-------|-------|
| `category_id` | required, exists:categories,id |
| `account_id` | required, exists:accounts,id |
| `saving_goal_id` | nullable, exists:saving_goals,id |
| `type` | required, in:income,expense |
| `amount` | required, numeric, >0 |
| `description` | nullable, string, max:1000 |
| `transaction_date` | required, date |
| `pending_source` | nullable, in:manual,push_notif,ocr |

### Show / Update / Delete

```http
GET /api/transactions/{id}
PUT /api/transactions/{id}
DELETE /api/transactions/{id}
```

Update rules (sometimes required):
| Field | Rules |
|-------|-------|
| `category_id` | sometimes, required, exists:categories,id |
| `account_id` | sometimes, required, exists:accounts,id |
| `saving_goal_id` | nullable, exists:saving_goals,id |
| `type` | sometimes, required, in:income,expense |
| `amount` | sometimes, required, numeric, >0 |
| `description` | nullable, string, max:1000 |
| `transaction_date` | sometimes, required, date |

---

## Pending Transactions

Transaksi hasil parsing email otomatis yang menunggu approve user.

### List

```http
GET /api/pending-transactions?page=1&per_page=20
Authorization: Bearer <token>
```

### Approve

```http
PATCH /api/pending-transactions/{id}/approve
Authorization: Bearer <token>
Content-Type: application/json

{
  "category_id": 1,
  "account_id": 1,
  "description": "optional override"
}
```

### Reject

```http
DELETE /api/pending-transactions/{id}/reject
Authorization: Bearer <token>
```

---

## Pending Notifications

**Dari Flutter** — notifikasi HP (push_notif) atau hasil scan OCR struk.

### List

```http
GET /api/pending-notifications?page=1&per_page=20
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "type": "expense",
      "amount": 50000.00,
      "description": "Pembelian Indomaret",
      "merchant": "Indomaret",
      "notification_date": "2026-06-23",
      "raw_body": "Pembelian Rp50.000 di Indomaret",
      "image_path": "storage/ocr-receipts/abc123.jpg",
      "source": "push_notif",
      "status": "pending",
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "total": 5 }
}
```

### Create (dari Flutter)

Notif HP atau OCR yang sudah diparse di Flutter, dikirim ke server.

```http
POST /api/pending-notifications
Authorization: Bearer <token>
Content-Type: multipart/form-data

{
  "type": "expense",
  "amount": 50000,
  "description": "optional",
  "merchant": "Indomaret",
  "notification_date": "2026-06-23",
  "raw_body": "teks asli dari notif/ocr",
  "image": (file, optional, untuk OCR),
  "source": "push_notif|ocr"
}
```

Validation rules:
| Field | Rules |
|-------|-------|
| `type` | required, in:income,expense |
| `amount` | required, numeric, >0 |
| `description` | nullable, string, max:1000 |
| `merchant` | nullable, string, max:255 |
| `notification_date` | nullable, date |
| `raw_body` | nullable, string |
| `image` | nullable, image, mimes:jpeg,png,jpg,gif,webp, max:5120 |
| `source` | required, in:push_notif,ocr |

### Approve (konversi ke transaksi)

```http
PATCH /api/pending-notifications/{id}/approve
Authorization: Bearer <token>
Content-Type: application/json

{
  "category_id": 1,
  "account_id": 1,
  "description": "optional override"
}
```

Validation rules:
| Field | Rules |
|-------|-------|
| `category_id` | **required**, `Rule::exists('categories')->where('user_id', auth()->id())` |
| `account_id` | **required**, `Rule::exists('accounts')->where('user_id', auth()->id())` |
| `description` | nullable, string, max:1000 |

> `category_id` & `account_id` diverifikasi milik user yang login, bukan global.

**Response `200`:**
```json
{
  "message": "Transaksi berhasil dibuat dari notifikasi",
  "transaction": {
    "id": 1,
    "type": "expense",
    "amount": 50000.00,
    "description": "Indomaret",
    "transaction_date": "2026-06-23",
    "is_pending": false,
    "pending_source": "push_notif",
    "category": { "id": 1, "name": "Makanan" },
    "account": { "id": 1, "name": "Cash / Dompet" }
  }
}
```

### Reject

```http
DELETE /api/pending-notifications/{id}/reject
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "message": "Notifikasi ditolak"
}
```

**Error `400`** (jika sudah diproses sebelumnya):
```json
{
  "message": "Notifikasi sudah diproses"
}
```

### Count Unread

```http
GET /api/pending-notifications/count
Authorization: Bearer <token>
```

```json
{ "pending_count": 5 }
```

---

## Budgets

### List

```http
GET /api/budgets?month=6&year=2026
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "amount": 1000000.00,
      "spent": 500000.00,
      "progress": 50.0,
      "is_over_budget": false,
      "month": 6,
      "year": 2026,
      "category": {
        "id": 1,
        "name": "Makanan",
        "type": "expense",
        "icon": "utensils",
        "color": "#ef4444"
      },
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

### Create

```http
POST /api/budgets
Authorization: Bearer <token>
Content-Type: application/json

{
  "category_id": 1,
  "amount": 1000000,
  "month": 6,
  "year": 2026
}
```

Validation rules:
| Field | Rules |
|-------|-------|
| `category_id` | required, exists:categories,id |
| `amount` | required, numeric, >0 |
| `month` | required, integer, between:1-12 |
| `year` | required, integer, min:2020, max:2099 |

### Show / Update / Delete

```http
GET /api/budgets/{id}
PUT /api/budgets/{id}
DELETE /api/budgets/{id}
```

---

## Saving Goals

### List

```http
GET /api/saving-goals
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Liburan Bali",
      "target_amount": 5000000.00,
      "current_amount": 1000000.00,
      "remaining": 4000000.00,
      "progress": 20.0,
      "deadline": "2026-12-31",
      "icon": "beach",
      "image": null,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

### Create

```http
POST /api/saving-goals
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Liburan Bali",
  "target_amount": 5000000,
  "current_amount": 0,
  "deadline": "2026-12-31",
  "icon": "beach",
  "image": null
}
```

Validation rules:
| Field | Rules |
|-------|-------|
| `name` | required, string, max:255 |
| `target_amount` | required, numeric, >0 |
| `current_amount` | nullable, numeric, min:0 |
| `deadline` | nullable, date, after:today |
| `icon` | nullable, string, max:50 |
| `image` | nullable, string, max:255 |

### Show / Update / Delete

```http
GET /api/saving-goals/{id}
PUT /api/saving-goals/{id}
DELETE /api/saving-goals/{id}
```

---

## Reports

### Monthly Summary

```http
GET /api/reports/monthly?month=6&year=2026
Authorization: Bearer <token>
```

```json
{
  "month": 6,
  "year": 2026,
  "total_income": 3000000.00,
  "total_expense": 1500000.00,
  "balance": 1500000.00
}
```

### Category Breakdown

```http
GET /api/reports/categories?type=expense&month=6&year=2026
Authorization: Bearer <token>
```

```json
{
  "type": "expense",
  "month": 6,
  "year": 2026,
  "categories": [
    {
      "category_id": 1,
      "category_name": "Makanan",
      "category_icon": "utensils",
      "category_color": "#ef4444",
      "total": 500000.00
    }
  ]
}
```

### Monthly Trend

```http
GET /api/reports/trend?year=2026
Authorization: Bearer <token>
```

```json
{
  "year": 2026,
  "trend": [
    { "month": 1, "month_name": "January", "income": 0, "expense": 0, "net": 0 },
    { "month": 2, "month_name": "February", "income": 0, "expense": 0, "net": 0 },
    { "month": 6, "month_name": "June", "income": 3000000, "expense": 1500000, "net": 1500000 }
  ]
}
```

### Export

```http
GET /api/reports/export?format=csv&month=6&year=2026
Authorization: Bearer <token>
```

Response: file download (CSV or PDF)

---

## Settings

### Show

```http
GET /api/settings
Authorization: Bearer <token>
```

```json
{
  "id": 1,
  "email_notifications": true,
  "budget_alerts": true,
  "email_fetch_enabled": false,
  "theme": "light",
  "created_at": "...",
  "updated_at": "..."
}
```

### Update

```http
PUT /api/settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "email_notifications": true,
  "budget_alerts": true,
  "email_fetch_enabled": false,
  "theme": "light|dark"
}
```

### Change Password

```http
PUT /api/settings/password
Authorization: Bearer <token>
Content-Type: application/json

{
  "current_password": "oldpassword123",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

---

## OAuth / Google

### Connection Status

```http
GET /api/oauth/status
Authorization: Bearer <token>
```

```json
{
  "connected": true,
  "email": "user@gmail.com",
  "email_fetch_enabled": true,
  "expires_at": "2026-07-23T12:00:00.000000Z"
}
```

### Disconnect

```http
DELETE /api/oauth/google
Authorization: Bearer <token>
```

```json
{ "message": "Google berhasil diputuskan." }
```

---

## Alerts

```http
GET /api/alerts/daily
Authorization: Bearer <token>
```

```json
{
  "alert": "Akun Cash / Dompet memiliki saldo negatif! | Budget Makanan telah melebihi batas!"
}
```

Atau jika tidak ada alert:
```json
{
  "alert": null
}
```

Alert ini di-cache sampai akhir hari. Cek:
- Saldo negatif
- Budget over budget
- Budget >= 80%

---

## Upload

```http
POST /api/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: (jpeg/png/jpg/gif/webp, max 2MB)
```

```json
{
  "message": "File berhasil diupload",
  "path": "uploads/filename.jpg",
  "url": "https://finarus.app/storage/uploads/filename.jpg"
}
```

---

## Error Response Format

```json
// 422 Validation Error
{
  "message": "Kredensial yang diberikan tidak cocok.",
  "errors": {
    "email": ["Kredensial yang diberikan tidak cocok."]
  }
}

// 401 Unauthenticated
{
  "message": "Unauthenticated."
}

// 404 Not Found
{
  "message": "No query results for model [App\\Models\\Transaction] 1"
}

// 400 Bad Request
{
  "message": "Notifikasi sudah diproses"
}

// 403 Forbidden
{
  "message": "This action is unauthorized."
}

// 500 Server Error
{
  "message": "Terjadi kesalahan server."
}
```

---

## Complete Endpoint List

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | No | Register email/password |
| POST | `/api/auth/login` | No | Login email/password |
| POST | `/api/auth/google` | No | Login/register via Google ID token |
| POST | `/api/logout` | Yes | Logout (revoke token) |
| GET | `/api/me` | Yes | Current user data |
| GET | `/api/dashboard` | Yes | Dashboard summary |
| GET | `/api/categories` | Yes | List categories |
| POST | `/api/categories` | Yes | Create category |
| GET | `/api/categories/{id}` | Yes | Show category |
| PUT | `/api/categories/{id}` | Yes | Update category |
| DELETE | `/api/categories/{id}` | Yes | Delete category |
| GET | `/api/accounts` | Yes | List accounts (with total_balance meta) |
| POST | `/api/accounts` | Yes | Create account |
| GET | `/api/accounts/{id}` | Yes | Show account |
| PUT | `/api/accounts/{id}` | Yes | Update account |
| DELETE | `/api/accounts/{id}` | Yes | Delete account (blocked if has transactions) |
| GET | `/api/transactions` | Yes | List transactions (paginated, filterable) |
| POST | `/api/transactions` | Yes | Create transaction |
| GET | `/api/transactions/{id}` | Yes | Show transaction |
| PUT | `/api/transactions/{id}` | Yes | Update transaction |
| DELETE | `/api/transactions/{id}` | Yes | Delete transaction |
| GET | `/api/pending-transactions` | Yes | List pending (from email parse) |
| PATCH | `/api/pending-transactions/{id}/approve` | Yes | Approve pending |
| DELETE | `/api/pending-transactions/{id}/reject` | Yes | Reject pending |
| GET | `/api/budgets` | Yes | List budgets (with spent/progress) |
| POST | `/api/budgets` | Yes | Create budget |
| GET | `/api/budgets/{id}` | Yes | Show budget |
| PUT | `/api/budgets/{id}` | Yes | Update budget |
| DELETE | `/api/budgets/{id}` | Yes | Delete budget |
| GET | `/api/saving-goals` | Yes | List saving goals (with progress/remaining) |
| POST | `/api/saving-goals` | Yes | Create saving goal |
| GET | `/api/saving-goals/{id}` | Yes | Show saving goal |
| PUT | `/api/saving-goals/{id}` | Yes | Update saving goal |
| DELETE | `/api/saving-goals/{id}` | Yes | Delete saving goal |
| GET | `/api/reports/monthly` | Yes | Monthly income/expense summary |
| GET | `/api/reports/categories` | Yes | Category breakdown |
| GET | `/api/reports/trend` | Yes | 12-month trend |
| GET | `/api/reports/export` | Yes | Export CSV/PDF |
| GET | `/api/settings` | Yes | Get user settings |
| PUT | `/api/settings` | Yes | Update user settings |
| PUT | `/api/settings/password` | Yes | Change password |
| GET | `/api/oauth/status` | Yes | Google connection status |
| DELETE | `/api/oauth/google` | Yes | Disconnect Google |
| POST | `/api/upload` | Yes | Upload image file |
| GET | `/api/pending-notifications` | Yes | List pending notifications |
| POST | `/api/pending-notifications` | Yes | Create notification (from Flutter) |
| PATCH | `/api/pending-notifications/{id}/approve` | Yes | Approve → convert to transaction |
| DELETE | `/api/pending-notifications/{id}/reject` | Yes | Reject notification |
| GET | `/api/pending-notifications/count` | Yes | Count pending notifications |
| GET | `/api/alerts/daily` | Yes | Daily alerts/reminders |

---

## Catatan Penting

### 1. Token Management
- **Simpan token** setelah login/register dengan `flutter_secure_storage`
- **Setiap request** sertakan header `Authorization: Bearer <token>`
- **401 response** = token expired/invalid → logout paksa user
- **Tidak ada refresh token** — Sanctum token berlaku sampai logout

### 2. ApiService Pattern (Dio)
```dart
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://finarus.app/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Force logout
        }
        return handler.next(error);
      },
    ));
  }
}
```

### 3. Data Models — Match dengan Eloquent casts
```dart
class Transaction {
  final int id;
  final String type;        // "income" | "expense"
  final double amount;      // decimal(15,2) → double
  final String? description;
  final String transactionDate;  // date → "Y-m-d"
  final Category? category;
  final Account? account;
  final SavingGoal? savingGoal;
  final bool isPending;     // boolean
  final String? pendingSource;
  final String createdAt;
  final String updatedAt;
}
```

### 4. Pagination Handling
```dart
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
}

// Gunakan infinite scroll:
// Endpoint: GET /api/transactions?page=1&per_page=20
// Load more: GET /api/transactions?page=2&per_page=20
```

### 5. Google Sign-In Notes
- **Web**: pake Socialite redirect flow
- **Mobile**: pake `google_sign_in`, kirim `idToken` ke `POST /api/auth/google`
- Backend verifikasi ID token via `Google\Client::verifyIdToken()`
- User baru akan auto-register + dibuatkan akun "Cash / Dompet"

### 6. Email Notifications (Server) vs Push Notif (Flutter)
| Source | Parser | Lokasi | Cara Kerja |
|--------|--------|--------|------------|
| **Email** | BcaParser, MandiriParser, etc. | **Server** | Fetch Gmail → parse body → jadi pending transaction |
| **Notif HP** | Manual di Flutter | **Flutter** | Tangkap notif → parse → kirim ke `/api/pending-notifications` |
| **OCR** | Manual di Flutter | **Flutter** | Kamera + `google_mlkit` → parse → kirim ke `/api/pending-notifications` + gambar |

### 7. Storage Strategy
```dart
class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'cached_user';

  static Future<void> saveToken(String token) async {
    await FlutterSecureStorage().write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await FlutterSecureStorage().read(key: _tokenKey);
  }

  static Future<void> clearAll() async {
    await FlutterSecureStorage().deleteAll();
  }
}
```

### 8. Initial App Load Flow
```
SplashScreen
  ├── Cek token di secure storage
  │   ├── Ada → GET /api/me
  │   │   ├── 200 → HomeScreen
  │   │   └── 401 → LoginScreen
  │   └── Tidak ada → LoginScreen
  │
LoginScreen
  ├── Form email/password → POST /api/auth/login
  ├── Google Sign-In → POST /api/auth/google
  └── Register form → POST /api/auth/register
```
