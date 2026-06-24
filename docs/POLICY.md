# Finarus Authorization Policies

Semua policy menerapkan **user ownership** — setiap user hanya bisa akses data miliknya sendiri.

---

## Policy per Model

### TransactionPolicy

| Method | Rule |
|--------|------|
| `viewAny` | ✅ always true (scoping via `$user->transactions()`) |
| `view` | `user_id === auth()->id()` |
| `create` | ✅ always true |
| `update` | `user_id === auth()->id()` |
| `delete` | `user_id === auth()->id()` |

### CategoryPolicy

| Method | Rule |
|--------|------|
| `viewAny` | ✅ always true |
| `view` | `user_id === auth()->id()` |
| `create` | ✅ always true |
| `update` | `user_id === auth()->id()` |
| `delete` | `user_id === auth()->id()` |

### AccountPolicy

| Method | Rule |
|--------|------|
| `viewAny` | ✅ always true |
| `view` | `user_id === auth()->id()` |
| `create` | ✅ always true |
| `update` | `user_id === auth()->id()` |
| `delete` | `user_id === auth()->id()` |

### BudgetPolicy

| Method | Rule |
|--------|------|
| `viewAny` | ✅ always true |
| `view` | `user_id === auth()->id()` |
| `create` | ✅ always true |
| `update` | `user_id === auth()->id()` |
| `delete` | `user_id === auth()->id()` |

### SavingGoalPolicy

| Method | Rule |
|--------|------|
| `viewAny` | ✅ always true |
| `view` | `user_id === auth()->id()` |
| `create` | ✅ always true |
| `update` | `user_id === auth()->id()` |
| `delete` | `user_id === auth()->id()` |

### PendingNotificationPolicy

| Method | Rule |
|--------|------|
| `viewAny` | ✅ always true |
| `view` | `user_id === auth()->id()` |
| `create` | ✅ always true |
| `update` | `user_id === auth()->id()` |
| `delete` | `user_id === auth()->id()` |

---

## Pola Umum

- **`viewAny`** — selalu `true` karena filtering dilakukan di controller via relasi `$user->model()`
- **`create`** — selalu `true` karena `user_id` di-set dari `Auth::id()` saat create
- **`view`/`update`/`delete`** — wajib cocok `user_id` model dengan `auth()->id()`
- Policy dipanggil di controller via `$this->authorize('ability', $model)` atau di `Request::validate()` via `Rule::exists(...)->where('user_id', auth()->id())`

## Contoh Penggunaan

**Controller:**
```php
public function update(Request $request, Transaction $transaction): JsonResponse
{
    $this->authorize('update', $transaction);
    // ...
}
```

**Validation (ownership):**
```php
$validated = $request->validate([
    'category_id' => ['required', Rule::exists('categories', 'id')->where('user_id', Auth::id())],
    'account_id' => ['required', Rule::exists('accounts', 'id')->where('user_id', Auth::id())],
]);
```

## Error Response

Jika policy tidak lolos, Laravel return `403 Forbidden`:
```json
{
  "message": "This action is unauthorized."
}
```
