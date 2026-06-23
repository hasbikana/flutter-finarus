import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/notification_provider.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../models/app_notification.dart';
import '../models/pending_notification.dart';
import '../widgets/glass_card.dart';
import '../utils/format.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final pendingItems = notifProvider.pendingItems;
    final localHistory = notifProvider.localHistory.reversed.toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
        actions: [
          if (localHistory.isNotEmpty)
            TextButton(
              onPressed: () => notifProvider.markAllLocalAsRead(),
              child: const Text('Tandai Baca'),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => notifProvider.fetchPending(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                if (pendingItems.isNotEmpty) ...[
                  _SectionTitle('Menunggu Konfirmasi (${pendingItems.length})'),
                  const SizedBox(height: 12),
                  ...pendingItems.map((p) => _PendingCard(
                    pending: p,
                    onApprove: () => _showApproveSheet(context, p),
                    onReject: () => _rejectPending(context, p),
                  )),
                  const SizedBox(height: 28),
                ],
                if (localHistory.isNotEmpty) ...[
                  _SectionTitle('Riwayat'),
                  const SizedBox(height: 12),
                  ...localHistory.map((n) => _HistoryCard(notification: n)),
                ] else if (pendingItems.isEmpty) ...[
                  const SizedBox(height: 80),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Belum ada notifikasi', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showApproveSheet(BuildContext context, PendingNotification pending) async {
    final catProvider = context.read<CategoryProvider>();
    final accProvider = context.read<AccountProvider>();
    if (catProvider.categories.isEmpty) await catProvider.loadCategories();
    if (accProvider.accounts.isEmpty) await accProvider.loadAccounts();

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        borderRadius: 24,
        child: _ApproveSheet(
          pending: pending,
          onSubmit: (catId, accId, desc) async {
            return context.read<NotificationProvider>().approvePending(
              pending.id,
              catId,
              accId,
              description: desc,
            );
          },
        ),
      ),
    );
  }

  Future<void> _rejectPending(BuildContext context, PendingNotification pending) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Transaksi?'),
        content: const Text('Data ini akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tolak', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<NotificationProvider>().rejectPending(pending.id);
    }
  }
}

// ── Widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: FinarusColors.foreground,
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingNotification pending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({
    required this.pending,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = pending.type == 'income';
    final color = isIncome ? FinarusColors.income : FinarusColors.expense;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.merchant ?? pending.description ?? 'Transaksi',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: FinarusColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatRupiah(pending.amount),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FinarusColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pending.source == 'ocr' ? 'OCR' : 'Push',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: FinarusColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (pending.rawBody != null && pending.rawBody!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FinarusColors.secondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pending.rawBody!,
                style: TextStyle(fontSize: 12, color: FinarusColors.mutedFg),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassButton(
                  onPressed: onApprove,
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AppNotification notification;

  const _HistoryCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'budget_over':
        icon = Icons.warning_amber;
        color = FinarusColors.expense;
        break;
      case 'budget_warning':
        icon = Icons.info_outline;
        color = FinarusColors.chartOrange;
        break;
      case 'balance_minus':
        icon = Icons.account_balance_wallet;
        color = Colors.red;
        break;
      case 'transaction_income':
        icon = Icons.arrow_upward;
        color = FinarusColors.income;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Opacity(
      opacity: notification.isRead ? 0.6 : 1.0,
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: FinarusColors.foreground,
              ),
            ),
            subtitle: Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: FinarusColors.mutedFg),
            ),
            trailing: Text(
              _timeAgo(notification.createdAt),
              style: TextStyle(fontSize: 11, color: FinarusColors.mutedFg),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}j';
    if (diff.inDays < 7) return '${diff.inDays}h';
    return '${date.day}/${date.month}';
  }
}

class _ApproveSheet extends StatefulWidget {
  final PendingNotification pending;
  final Future<bool> Function(int catId, int accId, String? desc) onSubmit;

  const _ApproveSheet({required this.pending, required this.onSubmit});

  @override
  State<_ApproveSheet> createState() => _ApproveSheetState();
}

class _ApproveSheetState extends State<_ApproveSheet> {
  int? _categoryId;
  int? _accountId;
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final accounts = context.watch<AccountProvider>().accounts;
    final type = widget.pending.type;
    final filteredCats = categories.where((c) => c.type == type || c.type == 'both').toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Konfirmasi Transaksi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.pending.merchant ?? "Transaksi"} - ${formatRupiah(widget.pending.amount)}',
            style: const TextStyle(color: FinarusColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
            ),
            items: filteredCats.map((c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text('${c.icon ?? ""} ${c.name}'),
            )).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Akun',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
            ),
            items: accounts.map((a) => DropdownMenuItem<int>(
              value: a.id,
              child: Text(a.name),
            )).toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Deskripsi (opsional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          GlassButton(
            onPressed: (_categoryId == null || _accountId == null || _submitting)
                ? null
                : () async {
                    setState(() => _submitting = true);
                    final success = await widget.onSubmit(
                      _categoryId!,
                      _accountId!,
                      _descController.text.isNotEmpty ? _descController.text : null,
                    );
                    if (mounted) {
                      setState(() => _submitting = false);
                      if (success) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaksi disimpan')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal menyimpan transaksi')),
                        );
                      }
                    }
                  },
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Simpan Transaksi'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
