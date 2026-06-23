import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/user_settings.dart';
import '../widgets/glass_card.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      context.read<SettingsProvider>().loadOAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sp = context.watch<SettingsProvider>();
    final settings = sp.settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: sp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                children: [
                  GlassCard(
                    borderRadius: 20,
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: FinarusColors.gradientCard,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              (auth.user?.name ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.user?.name ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  auth.user?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (settings != null) ...[
                    GlassCard(
                      borderRadius: 20,
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Notifikasi Email',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              subtitle: const Text(
                                'Terima notifikasi via email',
                                style: TextStyle(color: FinarusColors.mutedFg),
                              ),
                              value: settings.emailNotifications,
                              onChanged: (v) => _updateSetting(
                                context,
                                settings.copyWith(emailNotifications: v),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: FinarusColors.border.withValues(alpha: 0.5),
                            ),
                            SwitchListTile(
                              title: const Text(
                                'Peringatan Anggaran',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              subtitle: const Text(
                                'Dapatkan peringatan saat anggaran mendekati batas',
                                style: TextStyle(color: FinarusColors.mutedFg),
                              ),
                              value: settings.budgetAlerts,
                              onChanged: (v) => _updateSetting(
                                context,
                                settings.copyWith(budgetAlerts: v),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: FinarusColors.border.withValues(alpha: 0.5),
                            ),
                            SwitchListTile(
                              title: const Text(
                                'Peringatan Saldo Minus',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              subtitle: const Text(
                                'Notifikasi saat total saldo negatif',
                                style: TextStyle(color: FinarusColors.mutedFg),
                              ),
                              value: settings.balanceAlerts,
                              onChanged: (v) => _updateSetting(
                                context,
                                settings.copyWith(balanceAlerts: v),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: FinarusColors.border.withValues(alpha: 0.5),
                            ),
                            SwitchListTile(
                              title: const Text(
                                'Notifikasi Transaksi Masuk',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              subtitle: const Text(
                                'Beritahu saat ada pemasukan baru',
                                style: TextStyle(color: FinarusColors.mutedFg),
                              ),
                              value: settings.transactionAlerts,
                              onChanged: (v) => _updateSetting(
                                context,
                                settings.copyWith(transactionAlerts: v),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: FinarusColors.border.withValues(alpha: 0.5),
                            ),
                            SwitchListTile(
                              title: const Text(
                                'Auto-Capture Notifikasi',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              subtitle: const Text(
                                'Parse transaksi dari notifikasi aplikasi (DANA, dll)',
                                style: TextStyle(color: FinarusColors.mutedFg),
                              ),
                              value: settings.pushNotifications,
                              onChanged: (v) => _updateSetting(
                                context,
                                settings.copyWith(pushNotifications: v),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: FinarusColors.border.withValues(alpha: 0.5),
                            ),
                            SwitchListTile(
                              title: const Text(
                                'Ambil Email Otomatis',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              subtitle: const Text(
                                'Import transaksi dari Gmail',
                                style: TextStyle(color: FinarusColors.mutedFg),
                              ),
                              value: settings.emailFetchEnabled,
                              onChanged: (v) => _updateSetting(
                                context,
                                settings.copyWith(emailFetchEnabled: v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Google',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: FinarusColors.mutedFg,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: sp.isGoogleConnected
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Terhubung sebagai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: FinarusColors.mutedFg,
                                        ),
                                      ),
                                      Text(
                                        sp.googleEmail ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: FinarusColors.foreground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Hubungkan Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: FinarusColors.foreground,
                                    ),
                                  ),
                          ),
                          if (sp.isGoogleConnected)
                            TextButton(
                              onPressed: () => _confirmDisconnect(context),
                              child: const Text(
                                'Putuskan',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tentang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: FinarusColors.mutedFg,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      borderRadius: 20,
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text(
                                'Versi Aplikasi',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              trailing: const Text(
                                '1.0.0',
                                style: TextStyle(color: FinarusColors.mutedFg),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: FinarusColors.border.withValues(alpha: 0.5),
                            ),
                            ListTile(
                              title: const Text(
                                'Kebijakan Privasi',
                                style: TextStyle(color: FinarusColors.foreground),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: FinarusColors.mutedFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  void _updateSetting(BuildContext context, UserSettings newSettings) {
    context.read<SettingsProvider>().updateSettings(newSettings);
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Putuskan Google'),
        content: const Text(
          'Akun Google akan diputuskan dari Finarus. '
          'Fitur impor transaksi dari Gmail tidak akan berfungsi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Putuskan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final sp = context.read<SettingsProvider>();
      final success = await sp.disconnectGoogle();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sp.error ?? 'Gagal memutuskan Google')),
        );
      }
    }
  }
}
