# Finarus API Reference — Mobile (Flutter)

Base URL: `https://finarus.app/api` (sesuaikan)

Auth: **Bearer token** via Laravel Sanctum

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

Response `201`:
```json
{
  "message": "Registrasi berhasil",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "email_verified_at": null,
    "password_set_at": null,
    "created_at": "2026-06-23T...",
    "updated_at": "2026-06-23T..."
  },
  "token": "1|abc123..."
}
```

---

### Login (Email/Password)

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

Response `200`:
```json
{
  "message": "Login berhasil",
  "user": { "id": 1, "name": "John Doe", "email": "john@example.com", ... },
  "token": "1|abc123..."
}
```

Error `422`:
```json
{
  "message": "Kredensial yang diberikan tidak cocok.",
  "errors": { "email": ["Kredensial yang diberikan tidak cocok."] }
}
```

---

### Google Login (Mobile — ID Token)

> Backend memverifikasi `id_token` dari Google Sign-In menggunakan `Google\Client::verifyIdToken()`.

```http
POST /api/auth/google
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

**Flutter:**
```dart
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();
final GoogleSignInAccount? account = await _googleSignIn.signIn();
final GoogleSignInAuthentication auth = await account!.authentication;

final response = await http.post(
  Uri.parse('$baseUrl/api/auth/google'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'id_token': auth.idToken}),
);
```

Response `200` (user sudah ada):
```json
{
  "message": "Login berhasil",
  "user": { "id": 1, "name": "John Doe", "email": "john@gmail.com", ... },
  "token": "1|abc123..."
}
```

Response `201` (user baru — auto-register):
```json
{
  "message": "Registrasi berhasil",
  "user": { "id": 2, "name": "John Doe", "email": "john@gmail.com", ... },
  "token": "2|def456..."
}
```

Error `422`:
```json
{
  "message": "Token Google tidak valid.",
  "errors": { "id_token": ["Token Google tidak valid."] }
}
```

---

### Logout

```http
POST /api/logout
Authorization: Bearer <token>
```

Response `200`:
```json
{
  "message": "Logout berhasil"
}
```

---

### Current User

```http
GET /api/me
Authorization: Bearer <token>
```

Response `200`:
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "email_verified_at": null,
  "password_set_at": null,
  "created_at": "2026-06-23T...",
  "updated_at": "2026-06-23T..."
}
```

---

## Dashboard

```http
GET /api/dashboard
Authorization: Bearer <token>
```

Response `200`:
```json
{
  "total_balance": 5000000,
  "current_month_spending": 1500000,
  "current_month_income": 3000000,
  "active_budgets_count": 3,
  "pending_notifications_count": 2,
  "percentage_used": 50.0
}
```

---

## Categories

```http
GET /api/categories
Authorization: Bearer <token>
```

```http
POST /api/categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Makanan",
  "type": "expense",
  "icon": "utensils",
  "color": "#ef4444"
}
```

```http
GET /api/categories/{id}
PUT /api/categories/{id}
DELETE /api/categories/{id}
```

---

## Transactions

```http
GET /api/transactions?page=1&per_page=20&category_id=1&start_date=2026-01-01&end_date=2026-06-30&type=expense
Authorization: Bearer <token>
```

Response:
```json
{
  "data": [
    {
      "id": 1,
      "account_id": 1,
      "category_id": 1,
      "amount": 50000,
      "type": "expense",
      "description": "Nasi goreng",
      "transaction_date": "2026-06-23",
      "is_pending": false,
      "account": { "id": 1, "name": "Cash / Dompet" },
      "category": { "id": 1, "name": "Makanan", "icon": "utensils" }
    }
  ],
  "meta": { "current_page": 1, "last_page": 5, "total": 100 }
}
```

```http
POST /api/transactions
Authorization: Bearer <token>
Content-Type: application/json

{
  "account_id": 1,
  "category_id": 1,
  "amount": 50000,
  "type": "expense",
  "description": "Nasi goreng",
  "transaction_date": "2026-06-23",
  "is_pending": false
}
```

```http
GET /api/transactions/{id}
PUT /api/transactions/{id}
DELETE /api/transactions/{id}
```

---

## Pending Transactions

```http
GET /api/pending-transactions
Authorization: Bearer <token>
```

```http
PATCH /api/pending-transactions/{id}/approve
Authorization: Bearer <token>
```

```http
DELETE /api/pending-transactions/{id}/reject
Authorization: Bearer <token>
```

---

## Budgets

```http
GET /api/budgets
Authorization: Bearer <token>
```

```http
POST /api/budgets
Authorization: Bearer <token>
Content-Type: application/json

{
  "category_id": 1,
  "amount": 1000000,
  "period": "monthly",
  "start_date": "2026-06-01",
  "end_date": "2026-06-30"
}
```

```http
GET /api/budgets/{id}
PUT /api/budgets/{id}
DELETE /api/budgets/{id}
```

---

## Saving Goals

```http
GET /api/saving-goals
Authorization: Bearer <token>
```

```http
POST /api/saving-goals
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Liburan Bali",
  "target_amount": 5000000,
  "current_amount": 1000000,
  "target_date": "2026-12-31"
}
```

```http
GET /api/saving-goals/{id}
PUT /api/saving-goals/{id}
DELETE /api/saving-goals/{id}
```

---

## Accounts

```http
GET /api/accounts
Authorization: Bearer <token>
```

```http
POST /api/accounts
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "BCA",
  "provider": "Bank BCA",
  "type": "bank",
  "balance": 5000000
}
```

```http
GET /api/accounts/{id}
PUT /api/accounts/{id}
DELETE /api/accounts/{id}
```

---

## Reports

```http
GET /api/reports/monthly?year=2026&month=6
Authorization: Bearer <token>
```

```http
GET /api/reports/categories?start_date=2026-01-01&end_date=2026-06-30
Authorization: Bearer <token>
```

```http
GET /api/reports/trend?months=6
Authorization: Bearer <token>
```

```http
GET /api/reports/export?start_date=2026-01-01&end_date=2026-06-30
Authorization: Bearer <token>
```

---

## Settings

```http
GET /api/settings
Authorization: Bearer <token>
```

```http
PUT /api/settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "email_notifications": true,
  "budget_alerts": true,
  "theme": "light"
}
```

```http
PUT /api/settings/password
Authorization: Bearer <token>
Content-Type: application/json

{
  "current_password": "oldpassword",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

---

## OAuth / Google Connection

### Status

```http
GET /api/oauth/status
Authorization: Bearer <token>
```

Response `200`:
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

Response `200`:
```json
{
  "message": "Google berhasil diputuskan."
}
```

---

## Pending Notifications

```http
GET /api/pending-notifications?page=1&per_page=20
Authorization: Bearer <token>
```

```http
POST /api/pending-notifications
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Reminder",
  "message": "Bayar listrik",
  "type": "reminder",
  "scheduled_at": "2026-06-25 10:00:00"
}
```

```http
PATCH /api/pending-notifications/{id}/approve
Authorization: Bearer <token>
```

```http
DELETE /api/pending-notifications/{id}/reject
Authorization: Bearer <token>
```

```http
GET /api/pending-notifications/count
Authorization: Bearer <token>
```

Response `200`:
```json
{
  "count": 5
}
```

---

## Alerts

```http
GET /api/alerts/daily
Authorization: Bearer <token>
```

---

## Upload

```http
POST /api/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: (binary)
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
| GET | `/api/transactions` | Yes | List transactions |
| POST | `/api/transactions` | Yes | Create transaction |
| GET | `/api/transactions/{id}` | Yes | Show transaction |
| PUT | `/api/transactions/{id}` | Yes | Update transaction |
| DELETE | `/api/transactions/{id}` | Yes | Delete transaction |
| GET | `/api/pending-transactions` | Yes | List pending transactions |
| PATCH | `/api/pending-transactions/{id}/approve` | Yes | Approve pending |
| DELETE | `/api/pending-transactions/{id}/reject` | Yes | Reject pending |
| GET | `/api/budgets` | Yes | List budgets |
| POST | `/api/budgets` | Yes | Create budget |
| GET | `/api/budgets/{id}` | Yes | Show budget |
| PUT | `/api/budgets/{id}` | Yes | Update budget |
| DELETE | `/api/budgets/{id}` | Yes | Delete budget |
| GET | `/api/saving-goals` | Yes | List saving goals |
| POST | `/api/saving-goals` | Yes | Create saving goal |
| GET | `/api/saving-goals/{id}` | Yes | Show saving goal |
| PUT | `/api/saving-goals/{id}` | Yes | Update saving goal |
| DELETE | `/api/saving-goals/{id}` | Yes | Delete saving goal |
| GET | `/api/accounts` | Yes | List accounts |
| POST | `/api/accounts` | Yes | Create account |
| GET | `/api/accounts/{id}` | Yes | Show account |
| PUT | `/api/accounts/{id}` | Yes | Update account |
| DELETE | `/api/accounts/{id}` | Yes | Delete account |
| GET | `/api/reports/monthly` | Yes | Monthly report |
| GET | `/api/reports/categories` | Yes | Category report |
| GET | `/api/reports/trend` | Yes | Trend report |
| GET | `/api/reports/export` | Yes | Export report |
| GET | `/api/settings` | Yes | Get settings |
| PUT | `/api/settings` | Yes | Update settings |
| PUT | `/api/settings/password` | Yes | Change password |
| GET | `/api/oauth/status` | Yes | Google connection status |
| DELETE | `/api/oauth/google` | Yes | Disconnect Google |
| POST | `/api/upload` | Yes | Upload file |
| GET | `/api/pending-notifications` | Yes | List pending notifications |
| POST | `/api/pending-notifications` | Yes | Create pending notification |
| PATCH | `/api/pending-notifications/{id}/approve` | Yes | Approve notification |
| DELETE | `/api/pending-notifications/{id}/reject` | Yes | Reject notification |
| GET | `/api/pending-notifications/count` | Yes | Unread notification count |
| GET | `/api/alerts/daily` | Yes | Daily alerts |

---

## Error Response Format

Semua error mengikuti format yang konsisten:

```json
// Validation Error (422)
{
  "message": "Kredensial yang diberikan tidak cocok.",
  "errors": {
    "email": ["Kredensial yang diberikan tidak cocok."]
  }
}

// Unauthenticated (401)
{
  "message": "Unauthenticated."
}

// Not Found (404)
{
  "message": "Resource tidak ditemukan."
}

// Server Error (500)
{
  "message": "Terjadi kesalahan server."
}
```

---

## Catatan untuk Flutter Developer

1. **Simpan token** setelah login/register menggunakan `flutter_secure_storage`
2. **Sertakan token** di setiap request sebagai header `Authorization: Bearer <token>`
3. **Token tidak memiliki expiry** (Sanctum), tapi bisa di-revoke via logout
4. **Google login mobile** menggunakan ID token dari package `google_sign_in`, bukan access token
5. **Pagination** menggunakan parameter `page` dan `per_page` (default biasanya 20)
6. **Filter tanggal** menggunakan format `Y-m-d` (ISO 8601)
