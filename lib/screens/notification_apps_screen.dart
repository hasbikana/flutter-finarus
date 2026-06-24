import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../models/detected_app.dart';
import '../services/notif_listener_helper.dart';
import '../widgets/glass_card.dart';
import '../widgets/empty_state.dart';

class NotificationAppsScreen extends StatefulWidget {
  const NotificationAppsScreen({super.key});

  @override
  State<NotificationAppsScreen> createState() => _NotificationAppsScreenState();
}

class _NotificationAppsScreenState extends State<NotificationAppsScreen> {
  List<DetectedApp> _apps = [];
  bool _loading = true;
  String? _error;

  final _defaultFinancialApps = const {
    'id.dana',
    'com.android.dana',
    'com.dana',
    'com.gojek.gopay',
    'com.gojek.app',
    'gopay',
    'ovo.id',
    'com.ovo',
    'com.linkaja',
    'com.telkomsel.mytelkomsel',
    'com.shopee.id',
    'com.shopeepay',
    'com.bca',
    'com.bca.mobile.main',
    'id.co.bni',
    'id.co.bni.bnidirectmobile',
    'com.bri',
    'id.co.bri',
    'com.bri.brizzi.mobile',
    'com.bankmandiri',
    'com.bankmandiri.mandirionline',
    'com.paypal',
    'com.paypal.android',
    'com.ocbc',
    'com.seabank',
    'com.blu',
  };

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detected = await NotifListenerHelper.getDetectedApps();

      // Resolve app names
      final resolved = await Future.wait(
        detected.map((app) async {
          final name = await NotifListenerHelper.resolveAppName(app.appId);
          return app.copyWith(appName: name);
        }),
      );

      // Sort: new first, then allowed, then alphabetically
      resolved.sort((a, b) {
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        if (a.allowed != b.allowed) return a.allowed ? -1 : 1;
        final aName = (a.appName ?? a.appId).toLowerCase();
        final bName = (b.appName ?? b.appId).toLowerCase();
        return aName.compareTo(bName);
      });

      if (mounted) {
        setState(() {
          _apps = resolved;
          _loading = false;
        });
      }

      // Mark all as seen
      if (resolved.any((a) => a.isNew)) {
        await NotifListenerHelper.markAppsSeen(resolved.map((a) => a.appId).toList());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveAllowed(List<String> allowedIds) async {
    await NotifListenerHelper.setAllowedApps(allowedIds);
  }

  void _toggleApp(int index, bool value) {
    final updated = List<DetectedApp>.from(_apps);
    updated[index] = updated[index].copyWith(allowed: value);
    setState(() => _apps = updated);

    final allowedIds = updated.where((a) => a.allowed).map((a) => a.appId).toList();
    _saveAllowed(allowedIds);
  }

  void _selectAll(bool select) {
    final updated = _apps.map((a) => a.copyWith(allowed: select)).toList();
    setState(() => _apps = updated);
    _saveAllowed(select ? updated.map((a) => a.appId).toList() : []);
  }

  void _autoAllowFinancial() {
    final updated = _apps.map((a) {
      final isFinancial = _defaultFinancialApps.any((id) => a.appId.contains(id));
      return a.copyWith(allowed: a.allowed || isFinancial);
    }).toList();
    setState(() => _apps = updated);
    _saveAllowed(updated.where((a) => a.allowed).map((a) => a.appId).toList());
  }

  @override
  Widget build(BuildContext context) {
    final allowedCount = _apps.where((a) => a.allowed).length;
    final newCount = _apps.where((a) => a.isNew).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Kelola Aplikasi Capture'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
        actions: [
          if (_apps.isNotEmpty)
            TextButton(
              onPressed: () => _selectAll(_apps.every((a) => !a.allowed)),
              child: Text(
                _apps.every((a) => a.allowed) ? 'Hapus Semua' : 'Pilih Semua',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _loadApps)
                  : RefreshIndicator(
                      onRefresh: _loadApps,
                      child: _apps.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  message: 'Belum ada aplikasi yang terdeteksi.\n\nCoba terima notifikasi dari DANA, GoPay, OVO, atau BCA terlebih dahulu, lalu refresh halaman ini.',
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              children: [
                                _InfoCard(
                                  total: _apps.length,
                                  allowed: allowedCount,
                                  newApps: newCount,
                                  onAutoAllow: _autoAllowFinancial,
                                ),
                                const SizedBox(height: 16),
                                ..._apps.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final app = entry.value;
                                  return _AppTile(
                                    app: app,
                                    onToggle: (value) => _toggleApp(index, value),
                                  );
                                }),
                              ],
                            ),
                    ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final int total;
  final int allowed;
  final int newApps;
  final VoidCallback onAutoAllow;

  const _InfoCard({
    required this.total,
    required this.allowed,
    required this.newApps,
    required this.onAutoAllow,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aplikasi Terdeteksi: $total',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: FinarusColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Diizinkan: $allowed • Baru: $newApps',
            style: TextStyle(fontSize: 12, color: FinarusColors.mutedFg),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAutoAllow,
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('Auto-allow App Keuangan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FinarusColors.primary,
                side: BorderSide(color: FinarusColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final DetectedApp app;
  final ValueChanged<bool> onToggle;

  const _AppTile({
    required this.app,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.appName ?? app.appId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: FinarusColors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (app.isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: FinarusColors.chartOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: FinarusColors.chartOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  app.appId,
                  style: TextStyle(
                    fontSize: 11,
                    color: FinarusColors.mutedFg,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: app.allowed,
            onChanged: onToggle,
            activeColor: FinarusColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: FinarusColors.expense),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FinarusColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: FinarusColors.mutedFg),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
