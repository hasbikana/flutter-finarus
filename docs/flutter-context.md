# Flutter Agent Context: Finarus Mobile App

## Overview

Backend Laravel REST API sudah lengkap. Flutter app sudah jadi & terintegrasi. Sekarang perlu tambah **3 fitur semi-auto parser** menggunakan state management **Provider**.

---

## API Endpoints

| Method | Endpoint | Body / Notes |
|--------|----------|--------------|
| POST | `/api/auth/login` | `{ email, password }` → `{ user, token }` |
| POST | `/api/auth/register` | `{ name, email, password, password_confirmation }` → `{ user, token }` |
| POST | `/api/logout` | Auth required |
| GET | `/api/me` | Auth required → `{ id, name, email }` |
| GET | `/api/transactions?page=&per_page=&type=&search=&date_from=&date_to=` | List non-pending |
| POST | `/api/transactions` | `{ category_id, account_id, type, amount, description, transaction_date, pending_source? }` |
| GET | `/api/accounts` | User accounts |
| GET | `/api/categories` | User categories |
| GET | `/api/dashboard` | Summary + `pending_count` |
| **GET** | **`/api/pending-transactions`** | **List pending transaksi (dari Gmail)** |
| **PATCH** | **`/api/pending-transactions/{id}/approve`** | **`{ category_id, account_id, description? }`** |
| **DELETE** | **`/api/pending-transactions/{id}/reject`** | **Hapus pending** |
| **GET** | **`/api/pending-notifications`** | **List pending notifikasi (dari push_notif/ocr)** |
| **POST** | **`/api/pending-notifications`** | **Kirim hasil parse notif/OCR (simpan pending)** |
| **GET** | **`/api/pending-notifications/count`** | **Jumlah pending** |
| **PATCH** | **`/api/pending-notifications/{id}/approve`** | **`{ category_id, account_id, description? }` → create transaction** |
| **DELETE** | **`/api/pending-notifications/{id}/reject`** | **Tolak notif** |

---

## Data Models

### PendingNotification (Tabel Baru)
```json
{
  "id": 1,
  "type": "income|expense",
  "amount": 50000.00,
  "description": "Pembelian di Indomaret",
  "merchant": "Indomaret",
  "notification_date": "2026-06-23",
  "raw_body": "Pembelian Rp50.000 di Indomaret",
  "image_path": "ocr-receipts/xxx.jpg",
  "source": "push_notif|ocr",
  "status": "pending|confirmed|rejected",
  "created_at": "...",
  "updated_at": "..."
}
```

**POST /api/pending-notifications — Request (multipart untuk OCR):**
```dart
// Push notification (JSON):
{
  "type": "expense",
  "amount": 50000,
  "merchant": "Indomaret",
  "raw_body": "Pembelian Rp50.000 di Indomaret via BCA",
  "source": "push_notif"
}

// OCR (multipart):
{
  "type": "expense",
  "amount": 25000,
  "merchant": "Warung Budi",
  "description": "Nasi goreng + es teh",
  "notification_date": "2026-06-23",
  "raw_body": "WARUNG BUDI\nNasi Goreng 15000\nEs Teh 5000\nTotal 20000",
  "source": "ocr",
  "image": <file>
}
```

### Data Models

```dart
class TransactionDto {
  final int id;
  final String type; // income | expense
  final double amount;
  final String? description;
  final String transactionDate;
  final CategoryDto? category;
  final AccountDto? account;
  final bool isPending;
  final String? pendingSource; // email | push_notif | ocr | null
  // + fromJson factory
}

class AccountDto {
  final int id;
  final String name;
  final String? provider; // bca, mandiri, dll
  final String type; // bank | ewallet
  final double balance;
  // + fromJson factory
}

class CategoryDto {
  final int id;
  final String name;
  final String type; // income | expense
  final String? icon;
  final String? color;
  // + fromJson factory
}
```

---

## Provider Architecture

```dart
// lib/providers/pending_provider.dart
class PendingProvider extends ChangeNotifier {
  final ApiService _api;
  List<TransactionDto> _items = [];
  int _total = 0;
  bool _loading = false;

  List<TransactionDto> get items => _items;
  int get count => _items.length;
  bool get loading => _loading;

  Future<void> fetchPending() async { ... }
  Future<void> approve(int id, int categoryId, int accountId, {String? desc}) async { ... }
  Future<void> reject(int id) async { ... }
}

// lib/providers/notification_provider.dart
class NotificationProvider extends ChangeNotifier {
  final ApiService _api;
  List<NotifDraft> _drafts = [];

  List<NotifDraft> get drafts => _drafts;
  int get count => _drafts.length;

  Future<NotifDraft?> processNotification(RemoteMessage msg) async { ... }  // parse & simpan draft
  Future<void> confirmDraft(String draftId, int catId, int accId) async { ... }  // POST /api/transactions + pending_source=push_notif
  void dismissDraft(String draftId) { ... }
}

// lib/providers/ocr_provider.dart
class OcrProvider extends ChangeNotifier {
  bool _loading = false;
  OcrResult? _result;

  bool get loading => _loading;
  OcrResult? get result => _result;

  Future<void> processImage(XFile image) async { ... }  // ML Kit → parse
  Future<void> submit(int catId, int accId, String desc, String date) async { ... }  // POST /api/transactions + pending_source=ocr
  void reset() { ... }
}
```

---

## Push Notification Parser

### File: `lib/parsers/notification_parser.dart`

```dart
class NotificationParseResult {
  final String type;  // 'income' | 'expense'
  final double amount;
  final String? merchant;
}

class NotificationParser {
  // Input: body dari notifikasi (SMS / FCM)
  // Output: jumlah, tipe, merchant

  static NotificationParseResult? parse(String body) {
    // Cari nominal Rp
    final amountRegex = RegExp(r'[RpRp\s]*([0-9]+[.,]?[0-9]*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount == 0) return null;

    // Tentukan tipe
    final isDebit = body.contains(RegExp(r'debit|pembayaran|pembelian|belanja|tarik|transfer keluar', caseSensitive: false));
    final isCredit = body.contains(RegExp(r'kredit|menerima|transfer masuk|topup|isi saldo|dana masuk', caseSensitive: false));
    final type = isDebit ? 'expense' : (isCredit ? 'income' : 'expense');

    // Cari merchant/toko
    final merchantRegex = RegExp(r'(?:di|ke|pada|kepada|untuk)\s+(.+?)(?:\n|[.,!?]|$)', caseSensitive: false);
    final merchantMatch = merchantRegex.firstMatch(body);
    final merchant = merchantMatch?.group(1)?.trim();

    return NotificationParseResult(type: type, amount: amount, merchant: merchant);
  }
}
```

### File: `lib/providers/notification_provider.dart`

```dart
class NotifDraft {
  final String id;
  final String type;
  final double amount;
  final String? merchant;
  final DateTime createdAt;
}

class NotificationProvider extends ChangeNotifier {
  final ApiService _api;
  List<NotifDraft> _drafts = [];

  List<NotifDraft> get drafts => _drafts;
  bool get hasPending => _drafts.isNotEmpty;

  // Dipanggil saat FCM onMessage / onBackgroundMessage
  void addDraft(RemoteMessage message) {
    final notif = message.notification;
    final body = notif?.body ?? message.data['body'] ?? '';
    final parsed = NotificationParser.parse(body);
    if (parsed == null) return;

    // Cegah duplikat (berdasarkan title+body)
    final key = '${notif?.title}|${notif?.body}';
    if (_drafts.any((d) => d.id == key)) return;

    _drafts.insert(0, NotifDraft(
      id: key,
      type: parsed.type,
      amount: parsed.amount,
      merchant: parsed.merchant,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<bool> confirm({
    required String draftId,
    required int categoryId,
    required int accountId,
    String? description,
    String? date,
  }) async {
    final draft = _drafts.firstWhere((d) => d.id == draftId);
    try {
      await _api.post('/transactions', {
        'type': draft.type,
        'amount': draft.amount,
        'description': description ?? draft.merchant ?? '',
        'transaction_date': date ?? DateTime.now().toIso8601String().substring(0, 10),
        'category_id': categoryId,
        'account_id': accountId,
        'pending_source': 'push_notif',
      });
      _drafts.removeWhere((d) => d.id == draftId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void dismiss(String draftId) {
    _drafts.removeWhere((d) => d.id == draftId);
    notifyListeners();
  }
}
```

### FCM Integration (di main.dart atau service)

```dart
// lib/services/fcm_service.dart
class FcmService {
  static Future<void> init(NotificationProvider notifProvider) async {
    await Firebase.initializeApp();
    FirebaseMessaging.onMessage.listen((message) {
      notifProvider.addDraft(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      notifProvider.addDraft(message);
      // Navigasi ke halaman draft
    });
    final token = await FirebaseMessaging.instance.getToken();
    // Kirim token ke backend jika perlu
  }
}
```

---

## OCR Parser (ML Kit)

### File: `lib/parsers/ocr_parser.dart`

```dart
class OcrResult {
  final double? totalAmount;
  final String? merchant;
  final String? date;
  final String rawText;
}

class OcrParser {
  // Indonesian receipt patterns:
  // TOTAL : Rp 50.000
  // Total Belanja : 25.000
  // Jumlah : Rp15.000
  // Nama Toko (baris 1-2 biasanya nama toko)

  static OcrResult parse(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Cari total
    double? total;
    final totalRegex = RegExp(r'(?:total|jumlah|TOTAL|JUMLAH|Rp)[:\s]*Rp?\s?([0-9.,]+)', caseSensitive: false);
    for (final line in lines.reversed) {
      final match = totalRegex.firstMatch(line);
      if (match != null) {
        total = double.tryParse(match.group(1)!.replaceAll('.', '').replaceAll(',', '.'));
        break;
      }
    }

    // Cari merchant (biasanya baris 1 atau 2)
    String? merchant;
    if (lines.length >= 2) {
      merchant = lines[0].length < 30 ? lines[0] : lines[1];
    } else if (lines.isNotEmpty) {
      merchant = lines[0];
    }

    // Cari tanggal
    String? date;
    final dateRegex = RegExp(r'(\d{2}[/-]\d{2}[/-]\d{4})');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        date = match.group(1)!.replaceAll('/', '-');
        break;
      }
    }

    return OcrResult(
      totalAmount: total,
      merchant: merchant,
      date: date,
      rawText: rawText,
    );
  }
}
```

### File: `lib/providers/ocr_provider.dart`

```dart
class OcrProvider extends ChangeNotifier {
  final ApiService _api;
  bool _loading = false;
  OcrResult? _result;
  XFile? _image;

  bool get loading => _loading;
  OcrResult? get result => _result;
  XFile? get image => _image;

  Future<void> processImage(XFile image) async {
    _loading = true;
    _image = image;
    notifyListeners();

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognisedText = await recognizer.processImage(inputImage);
      final raw = recognisedText.text;
      _result = OcrParser.parse(raw);
      recognizer.close();
    } catch (e) {
      _result = OcrResult(totalAmount: null, merchant: null, date: null, rawText: '');
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> submit({
    required double amount,
    required String date,
    required String description,
    required int categoryId,
    required int accountId,
  }) async {
    try {
      // Upload image dulu jika perlu (POST /api/upload)
      String? imageUrl;
      if (_image != null) {
        final uploadRes = await _api.uploadImage(_image!);
        imageUrl = uploadRes['url'];
      }

      await _api.post('/transactions', {
        'type': 'expense',
        'amount': amount,
        'description': description + (imageUrl != null ? '\n[gambar: $imageUrl]' : ''),
        'transaction_date': date,
        'category_id': categoryId,
        'account_id': accountId,
        'pending_source': 'ocr',
      });

      reset();
      return true;
    } catch (e) {
      return false;
    }
  }

  void reset() {
    _result = null;
    _image = null;
    _loading = false;
    notifyListeners();
  }
}
```

---

## Pending Gmail Page

### File: `lib/providers/pending_provider.dart`

```dart
class PendingProvider extends ChangeNotifier {
  final ApiService _api;
  List<TransactionDto> _items = [];
  bool _loading = false;
  int _page = 1;
  bool _hasMore = true;

  List<TransactionDto> get items => _items;
  int get count => _items.length;
  bool get loading => _loading;

  Future<void> fetchPending({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    if (_loading || !_hasMore) return;

    _loading = true;
    notifyListeners();

    try {
      final res = await _api.get('/pending-transactions', params: {'page': _page, 'per_page': 20});
      final List data = res['data'];
      if (refresh) {
        _items = data.map((j) => TransactionDto.fromJson(j)).toList();
      } else {
        _items.addAll(data.map((j) => TransactionDto.fromJson(j)));
      }
      _hasMore = _page < (res['meta']['last_page'] ?? 1);
      _page++;
    } catch (e) {
      // handle error
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> approve(int id, int categoryId, int accountId, {String? description}) async {
    try {
      await _api.patch('/pending-transactions/$id/approve', {
        'category_id': categoryId,
        'account_id': accountId,
        if (description != null) 'description': description,
      });
      _items.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reject(int id) async {
    try {
      await _api.delete('/pending-transactions/$id/reject');
      _items.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## UI Screens (Tinggal Tambah)

### 1. Confirm Bottom Sheet (Shared)

```dart
// lib/widgets/transaction_confirm_sheet.dart
class TransactionConfirmSheet extends StatelessWidget {
  final String type; // income/expense
  final double amount;
  final String? initialDescription;
  final String? initialDate;
  final VoidCallback? onSubmit;
  // Dropdown kategori & akun (ambil dari Provider masing2)
  // Tombol Simpan & Nanti/Tolak
}
```

### 2. Pending Screen

```dart
// lib/screens/pending_screen.dart
class PendingScreen extends StatelessWidget {
  // AppBar: "Transaksi Baru"
  // RefreshIndicator → pendingProvider.fetchPending(refresh: true)
  // ListView.builder dari pendingProvider.items
  // Setiap item: Icon provider, amount, deskripsi, tanggal
  // Tap → showModalBottomSheet(TransactionConfirmSheet) → approve/reject
  // Empty state: "Tidak ada transaksi pending"
}
```

### 3. OCR Screen

```dart
// lib/screens/ocr_screen.dart
class OcrScreen extends StatelessWidget {
  // Kamera preview (atau pilih gallery)
  // Setelah capture → ocrProvider.processImage()
  // Loading indicator
  // Hasil: form dengan amount, merchant, tanggal (auto fill, bisa diedit)
  // Dropdown kategori & akun
  // Tombol Simpan & Ulang
}
```

### 4. Notification Floating Action (Di Halaman Mana Pun)

```dart
// Di main scaffold, pantau notificationProvider.hasPending
// Tampilkan banner/bottom sheet jika ada draft baru
// notificationProvider.confirm() atau .dismiss()
```

---

## Register Providers

```dart
// lib/main.dart atau lib/providers/providers.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PendingProvider(api)),
    ChangeNotifierProvider(create: (_) => NotificationProvider(api)),
    ChangeNotifierProvider(create: (_) => OcrProvider(api)),
    // Provider lainnya (auth, categories, accounts, dsb)
  ],
  child: MaterialApp(...),
)
```

---

## Alur Baru: POST /api/pending-notifications

### Push Notification Flow (Flutter→Server→Web/Flutter)
```
FCM → Flutter parse → POST /api/pending-notifications { type, amount, merchant, raw_body, source: 'push_notif' }
  → Server simpan status=pending
  → Flutter & Web GET /api/pending-notifications → tampil di kedua platform
  → User approve di mana saja → PATCH /api/pending-notifications/{id}/approve { category_id, account_id }
    → Server: CREATE transaction (is_pending=false, pending_source=push_notif)
    → Server: UPDATE pending_notification status=confirmed
```

### OCR Flow (Flutter→Server→Web/Flutter)
```
Camera → ML Kit → parse teks
  → POST /api/pending-notifications { type: 'expense', amount, merchant, description, raw_body, source: 'ocr' }
    + upload image (multipart: field 'image')
  → Sama seperti push notif: muncul di pending → approve/reject
```

### Update NotificationProvider
```dart
// Di notification_provider.dart, ganti confirm() jadi:
Future<bool> confirm({
  required String draftId,
  required int categoryId,
  required int accountId,
  String? description,
}) async {
  // Sebelumnya: POST /api/transactions langsung
  // Sekarang: POST /api/pending-notifications (agar bisa diakses web juga)
  final draft = _drafts.firstWhere((d) => d.id == draftId);
  try {
    await _api.post('/pending-notifications', {
      'type': draft.type,
      'amount': draft.amount,
      'merchant': draft.merchant,
      'raw_body': draft.rawBody,
      'source': 'push_notif',
    });
    _drafts.removeWhere((d) => d.id == draftId);
    notifyListeners();
    return true;
  } catch (e) {
    return false;
  }
}
```

### Update OcrProvider
```dart
// Di ocr_provider.dart, submit() sekarang upload image + data ke pending-notifications
Future<bool> submit({
  required double amount,
  required String date,
  required String description,
  required String merchant,
  required String rawText,
}) async {
  try {
    final formData = FormData.fromMap({
      'type': 'expense',
      'amount': amount,
      'merchant': merchant,
      'description': description,
      'notification_date': date,
      'raw_body': rawText,
      'source': 'ocr',
      if (_image != null)
        'image': await MultipartFile.fromFile(_image!.path, filename: 'receipt.jpg'),
    });
    await _api.post('/pending-notifications', formData);
    reset();
    return true;
  } catch (e) {
    return false;
  }
}
```

---

## Prioritas Implementasi

1. **PendingProvider + PendingScreen** — GET/PATCH/DELETE pending transaksi (Gmail)
2. **PendingNotificationProvider** — GET/POST/PATCH/DELETE pending notifikasi (push_notif/ocr) — bisa diakses web juga
3. **NotificationProvider + NotificationParser** — FCM setup + parse + POST pending-notifications
4. **OcrProvider + OcrParser + OcrScreen** — ML Kit + camera + POST pending-notifications (include image)
