# Backend Fix: 403 Forbidden saat Approve/Reject Pending Notification

> Issue: Flutter kirim request approve/reject pending notification dengan benar, tapi backend return `403 This action is unauthorized.`
> **Status: FIXED** — perbaikan sudah diterapkan di `app/Http/Controllers/Api/PendingNotificationController.php`.

---

## Root Cause

**Route model binding mismatch.**

Di `routes/api.php`:
```php
Route::patch('{pending_notification}/approve', [PendingNotificationController::class, 'approve']);
Route::delete('{pending_notification}/reject', [PendingNotificationController::class, 'reject']);
```

Parameter route: `pending_notification`

Tapi controller sebelumnya pakai:
```php
public function approve(Request $request, PendingNotification $notification)
public function reject(Request $request, PendingNotification $notification)
```

Laravel implicit route model binding **mencocokkan nama parameter route dengan nama variable di controller**. Karena `pending_notification` ≠ `notification`, Laravel tidak meng-resolve model dari database. Controller menerima **instance PendingNotification kosong** dengan `user_id = null`.

Policy kemudian cek:
```php
return $user->id === $pendingNotification->user_id;
// $pendingNotification->user_id === null → false → 403
```

---

## Fix yang Sudah Diterapkan

Di `app/Http/Controllers/Api/PendingNotificationController.php`, parameter controller diubah menjadi `$pending_notification` supaya cocok dengan nama parameter route:

```php
public function approve(Request $request, PendingNotification $pending_notification): JsonResponse
{
    $this->authorize('update', $pending_notification);

    if ($pending_notification->status !== 'pending') {
        return response()->json(['message' => 'Notifikasi sudah diproses'], 400);
    }

    // ... sisanya tetap sama, hanya ganti $notification → $pending_notification
}

public function reject(Request $request, PendingNotification $pending_notification): JsonResponse
{
    $this->authorize('delete', $pending_notification);

    if ($pending_notification->status !== 'pending') {
        return response()->json(['message' => 'Notifikasi sudah diproses'], 400);
    }

    // ... sisanya tetap sama
}
```

---

## Verifikasi

Setelah fix, seharusnya:

### Approve Sukses
```http
PATCH /api/pending-notifications/4/approve
Authorization: Bearer <token>

{
  "category_id": 12,
  "account_id": 5
}
```

Response:
```json
HTTP 200
{
  "message": "Transaksi berhasil dibuat dari notifikasi",
  "transaction": { ... }
}
```

### Reject Sukses
```http
DELETE /api/pending-notifications/4/reject
Authorization: Bearer <token>
```

Response:
```json
HTTP 200
{
  "message": "Notifikasi ditolak"
}
```

### Sudah Diproses
```json
HTTP 400
{
  "message": "Notifikasi sudah diproses"
}
```

---

## Catatan untuk Flutter

Sisi Flutter tidak perlu diubah. Endpoint, method, body, dan token sudah benar.

Jika masih ada error setelah fix ini, kemungkinan sisa:
1. Cache route Laravel belum di-clear (`php artisan route:clear`)
2. `user_id` di tabel `pending_notifications` memang salah (cek migration/seeder)
3. Policy/AuthServiceProvider bermasalah

---

## Perintah Laravel yang Perlu Dijalankan Setelah Edit

```bash
php artisan route:clear
php artisan cache:clear
php artisan config:clear
```

Kemudian test approve/reject dari Flutter lagi.
