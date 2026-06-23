import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/dashboard_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/notification_provider.dart';
import '../models/dashboard.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../widgets/progress_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../utils/format.dart';
import 'accounts_screen.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'savings_screen.dart';
import 'transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardAndCheckNotifications();
    });
  }

  Future<void> _loadDashboardAndCheckNotifications() async {
    final dashProvider = context.read<DashboardProvider>();
    final notifProvider = context.read<NotificationProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    try {
      // Load settings if not already loaded
      if (settingsProvider.settings == null) {
        await settingsProvider.loadSettings();
      }

      await dashProvider.loadDashboard();

      final dash = dashProvider.dashboard;
      final settings = settingsProvider.settings;

      if (dash != null && settings != null) {
        if (settings.budgetAlerts) {
          notifProvider.checkAndNotifyBudget(dash.budgetProgress);
        }
        if (settings.balanceAlerts) {
          notifProvider.checkAndNotifyBalance(dash.balance);
        }
        if (settings.transactionAlerts) {
          notifProvider.checkAndNotifyNewTransactions(dash.recentTransactions);
        }
      }

      await notifProvider.fetchPending();
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    debugPrint('Dashboard - isLoading: ${dash.isLoading}, dashboard: ${dash.dashboard}, error: ${dash.error}');

    if (dash.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dash.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 1),
            Text(
              dash.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadDashboardAndCheckNotifications(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (dash.dashboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada data', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadDashboardAndCheckNotifications(),
              child: const Text('Muat Data'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboardAndCheckNotifications(),
      child: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 20),
                child: Column(
                  children: [
                    _HeroCard(dashboard: dash.dashboard!),
                    const SizedBox(height: 24),
                    _QuickActionGrid(),
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'Transaksi Terbaru',
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (dash.dashboard!.recentTransactions.isEmpty)
                      const EmptyState(message: 'Belum ada transaksi')
                    else
                      ...dash.dashboard!.recentTransactions.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TransactionCard(transaction: t),
                        ),
                      ),
                    const SizedBox(height: 28),
                    if (dash.dashboard!.budgetProgress.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Anggaran Bulan Ini',
                        onSeeAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...dash.dashboard!.budgetProgress.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _BudgetCard(budget: b),
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}


class _HeroCard extends StatelessWidget {
  final Dashboard dashboard;
  const _HeroCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: FinarusColors.gradientCard,
        ),
        boxShadow: [
          BoxShadow(
            color: FinarusColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Saldo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatRupiah(dashboard.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Image.asset('lib/assets/logo/logodalam.png', width: 32, height: 32),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pemasukan',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatRupiah(dashboard.totalIncome),
                                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.2)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pengeluaran',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatRupiah(dashboard.totalExpense),
                                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Cepat',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: FinarusColors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _QuickActionItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Dompet',
              color: FinarusColors.primary,
              gradient: FinarusColors.gradientBlue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _QuickActionItem(
              icon: Icons.pie_chart_outline,
              label: 'Anggaran',
              color: FinarusColors.chartOrange,
              gradient: FinarusColors.gradientOrange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _QuickActionItem(
              icon: Icons.category_outlined,
              label: 'Kategori',
              color: FinarusColors.chartPurple,
              gradient: FinarusColors.gradientPurple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _QuickActionItem(
              icon: Icons.savings_outlined,
              label: 'Tabungan',
              color: FinarusColors.chartGreen,
              gradient: FinarusColors.gradientGreen,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsScreen())),
            )),
          ],
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: FinarusColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: FinarusColors.foreground,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: FinarusColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final iconColor = isIncome ? FinarusColors.income : FinarusColors.expense;
    final bgColor = isIncome ? FinarusColors.incomeLight : FinarusColors.expenseLight;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: iconColor, size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category?.name ?? transaction.description ?? 'Transaksi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: FinarusColors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formatDate(transaction.transactionDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: FinarusColors.mutedFg,
                      ),
                    ),
                    if (transaction.account != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: FinarusColors.secondary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.account!.name,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: FinarusColors.mutedFg),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${budget.category?.icon ?? ''} ${budget.category?.name ?? 'Anggaran'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: FinarusColors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${formatRupiah(budget.spent)} / ${formatRupiah(budget.amount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: FinarusColors.mutedFg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            progress: budget.progress,
            isOverBudget: budget.isOverBudget,
            gradient: budget.isOverBudget ? null : FinarusColors.gradientCard,
            height: 10,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${budget.progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: budget.isOverBudget ? FinarusColors.expense : FinarusColors.primary,
                ),
              ),
              const Spacer(),
              if (budget.isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FinarusColors.expenseLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Over Budget!',
                    style: TextStyle(
                      color: FinarusColors.expense,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
