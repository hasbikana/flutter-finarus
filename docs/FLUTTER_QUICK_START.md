# Finarus — Flutter Quick Start

## Base Configuration

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://YOUR_IP:8000/api';
  // Laragon: http://localhost/finarus/public/api
  // Production: https://your-domain.com/api
  
  static const Map<String, String> headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
```

## Auth Service

```dart
// POST /api/auth/login
// Response: { token: "1|abc...", user: { id, name, email } }

// POST /api/auth/register
// Response: { token: "2|xyz...", user: { id, name, email } }

// After login, store token in flutter_secure_storage
// All subsequent requests: Authorization: Bearer $token
```

## Color Constants

```dart
// lib/config/colors.dart
import 'package:flutter/material.dart';

class FinarusColors {
  // Light mode
  static const background      = Color(0xFFFFFFFF);
  static const foreground      = Color(0xFF020617);
  static const card            = Color(0xFFFFFFFF);
  static const primary         = Color(0xFF2563EB);
  static const primaryFg       = Color(0xFFF8FAFC);
  static const secondary       = Color(0xFFF1F5F9);
  static const muted           = Color(0xFFF1F5F9);
  static const mutedFg         = Color(0xFF64748B);
  static const destructive     = Color(0xFFEF4444);
  static const border          = Color(0xFFE2E8F0);
  
  // Dark mode
  static const darkBackground  = Color(0xFF020617);
  static const darkForeground  = Color(0xFFF8FAFC);
  static const darkCard        = Color(0xFF020A1C);
  static const darkPrimary     = Color(0xFF3B82F6);
  static const darkBorder      = Color(0xFF1E293B);
  
  // Chart colors
  static const chartBlue       = Color(0xFF2563EB);
  static const chartGreen      = Color(0xFF16A34A);
  static const chartRed        = Color(0xFFEF4444);
  static const chartOrange     = Color(0xFFF97316);
  static const chartPurple     = Color(0xFF8B5CF6);
  static const chartYellow     = Color(0xFFEAB308);
}
```

## Screens Needed (7 primary)

| Screen | API Endpoint(s) | Key Widgets |
|--------|----------------|-------------|
| **Login** | POST /api/auth/login | Form email+password, Google sign-in button |
| **Register** | POST /api/auth/register | Form name+email+password+confirm |
| **Dashboard** | GET /api/dashboard | 4 summary cards (Cash/E-Wallet/Bank/Savings), recent transactions list, budget progress bars |
| **Transaksi** | GET/POST/PUT/DELETE /api/transactions | Table list with search/filter, modal create/edit form, delete confirm |
| **Kategori** | GET/POST/PUT/DELETE /api/categories | Card grid with emoji+color, modal with emoji picker + color swatches |
| **Anggaran** | GET/POST/PUT/DELETE /api/budgets | Progress bars per category, add/edit modal |
| **Tabungan** | GET/POST/PUT/DELETE /api/saving-goals | Goal cards with progress + image, add fund modal, emoji picker |
| **Dompet** | GET/POST/PUT/DELETE /api/accounts | Account list grouped by type, logo grid picker |
| **Laporan** | GET /api/reports/monthly/categories/trend | Summary cards, bar chart (trend), doughnut chart (categories), export button |
| **Pengaturan** | GET/PUT /api/settings | Toggle switches: notifications, budget alerts, dark mode, email fetch |
| **Profile** | PUT /api/settings/password | Email display, password change form |

## Rupiah Formatting

```dart
String formatRupiah(num amount) {
  final format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return format.format(amount);
}
```

## Date Formatting

```dart
// Transaction dates in API: "2026-06-22"
// Display: "22 Jun 2026"
String formatDate(String isoDate) {
  final date = DateTime.parse(isoDate);
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                  'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
```

## Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  flutter_secure_storage: ^9.2.0
  provider: ^6.1.0       # state management
  fl_chart: ^0.68.0       # charts (like Chart.js)
  google_sign_in: ^6.2.0  # optional: Google OAuth
  image_picker: ^1.1.0    # for saving goal photos
  intl: ^0.19.0           # rupiah formatting
```

## App Structure Suggestion

```
lib/
├── main.dart                   # ThemeData + app entry
├── config/
│   ├── api_config.dart         # baseUrl, token storage
│   └── colors.dart             # FinarusColors
├── models/                     # All data classes
│   ├── user.dart
│   ├── category.dart
│   ├── transaction.dart
│   ├── account.dart
│   ├── budget.dart
│   ├── saving_goal.dart
│   └── dashboard.dart
├── services/
│   ├── auth_service.dart       # login, register, logout
│   ├── api_service.dart        # base HTTP methods with token
│   └── settings_service.dart   # theme + preferences
├── providers/                  # State management
│   ├── auth_provider.dart
│   ├── transaction_provider.dart
│   └── ...
├── screens/
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── categories_screen.dart
│   ├── budgets_screen.dart
│   ├── savings_screen.dart
│   ├── accounts_screen.dart
│   ├── reports_screen.dart
│   └── settings_screen.dart
└── widgets/                    # Reusable components
    ├── rupiah_text.dart
    ├── progress_bar.dart
    ├── color_picker.dart
    ├── emoji_picker.dart
    └── loading_button.dart
```
