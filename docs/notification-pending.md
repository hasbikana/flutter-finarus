# Alur Notifikasi Pending — Terima & Tolak

Dokumen ini khusus untuk Flutter AI agent: parameter, validasi, dan flow backend untuk approve/reject notifikasi pending.

---

## 1. Kirim Notifikasi ke Server (Create)

**Dari Flutter** — setelah parsing SMS notif HP atau hasil OCR, kirim ke:

```
POST /api/pending-notifications
Content-Type: multipart/form-data
```

### Parameter

| Field | Wajib | Tipe | Contoh |
|-------|-------|------|--------|
| `type` | ✅ | `income` / `expense` | `"expense"` |
| `amount` | ✅ | numeric > 0 | `50000` |
| `source` | ✅ | `push_notif` / `ocr` | `"push_notif"` |
| `description` | ❌ | string max 1000 | `"Indomaret"` |
| `merchant` | ❌ | string max 255 | `"Indomaret"` |
| `notification_date` | ❌ | date Y-m-d | `"2026-06-24"` |
| `raw_body` | ❌ | text | teks asli notif |
| `image` | ❌ | file (jpeg/png/jpg/gif/webp max 5MB) | foto struk |

### Response 201

```json
{
  "message": "Notifikasi berhasil disimpan",
  "notification": {
    "id": 3,
    "type": "expense",
    "amount": 50000.00,
    "source": "push_notif",
    "status": "pending"
  }
}
```

### Flow Flutter → Server

```
[Notification SMS] → [Flutter parse] → [POST /api/pending-notifications] → [DB pending_notifications]
[OCR Camera] → [Google ML Kit parse] → [POST /api/pending-notifications + image] → [DB pending_notifications]
```

---

## 2. Approve (Terima & Simpan Jadi Transaksi)

```
PATCH /api/pending-notifications/{id}/approve
```

### Parameter

| Field | Wajib | Tipe | Validasi |
|-------|-------|------|----------|
| `category_id` | ✅ | integer | Harus milik user yg login (`Rule::exists('categories')->where('user_id', auth()->id())`) |
| `account_id` | ✅ | integer | Harus milik user yg login (`Rule::exists('accounts')->where('user_id', auth()->id())`) |
| `description` | ❌ | string max 1000 | Override deskripsi, fallback: `merchant` → `description` |

### Yang Terjadi di Backend

1. Validasi ownership `category_id` & `account_id`
2. Validasi notifikasi masih `status = pending`
3. `TransactionService::createTransaction()`:
   - Insert ke tabel `transactions` dengan `is_pending = false`, `pending_source` = asal notif
   - Update saldo akun (`recalculateBalance()`)
4. Update `pending_notifications.status = 'confirmed'`

### Response 200

```json
{
  "message": "Transaksi berhasil dibuat dari notifikasi",
  "transaction": {
    "id": 10,
    "type": "expense",
    "amount": 50000.00,
    "description": "Indomaret",
    "transaction_date": "2026-06-24",
    "is_pending": false,
    "pending_source": "push_notif",
    "category": { "id": 1, "name": "Makanan" },
    "account": { "id": 1, "name": "Cash / Dompet" }
  }
}
```

### Flow Approve

```
[Flutter/Web] → PATCH /api/pending-notifications/3/approve
  ├── Cek: notifikasi status = pending?
  │   └── Tidak → 400 "Notifikasi sudah diproses"
  ├── Validasi: category_id milik user?
  ├── Validasi: account_id milik user?
  ├── Buat transaksi baru (is_pending = false)
  ├── Update saldo akun
  └── Update status notif → "confirmed"
```

---

## 3. Tolak (Reject)

```
DELETE /api/pending-notifications/{id}/reject
```

### Parameter

Tidak ada body. Cukup ID di URL.

### Yang Terjadi di Backend

1. Cek notifikasi masih `status = pending`
2. Update `pending_notifications.status = 'rejected'`
3. Data tetap di DB (soft reject — tidak dihapus)

### Response 200

```json
{
  "message": "Notifikasi ditolak"
}
```

### Error 400 (sudah diproses sebelumnya)

```json
{
  "message": "Notifikasi sudah diproses"
}
```

---

## 4. List & Count

### List Semua Pending

```
GET /api/pending-notifications?page=1&per_page=20
```

Filter otomatis: hanya milik user yg login, `status = pending`.

### Count

```
GET /api/pending-notifications/count
```

```json
{
  "pending_count": 3
}
```

Gunakan untuk badge/bell icon.

---

## 5. Catatan untuk Flutter

### State Flow Notifikasi

```
idle
  → user lihat list (GET) → loading
  → user tap "Setuju" → PATCH approve
      → loading → sukses (hapus dari list, update count)
      → error → tampilkan pesan
  → user tap "Tolak" → DELETE reject
      → loading → sukses (hapus dari list, update count)
      → error → tampilkan pesan
```

### Mapping Source ke UI

| `source` | Label | Icon |
|----------|-------|------|
| `push_notif` | Notif HP | 📱 |
| `ocr` | OCR | 📷 |

### Mapping Type ke UI

| `type` | Label | Warna |
|--------|-------|-------|
| `income` | Pemasukan | Hijau |
| `expense` | Pengeluaran | Merah |

### Error Handling

| HTTP | Arti | Handling |
|------|------|----------|
| `201` | Create sukses | Notif masuk list pending |
| `200` | Approve/Reject sukses | Hapus dari list, update count |
| `400` | "Notifikasi sudah diproses" | Refresh list (mungkin double tap) |
| `422` | Validasi gagal | Tampilkan error messages |
| `403` | Bukan milik user | Force refresh token / logout |
| `401` | Token expired | Redirect ke login |
