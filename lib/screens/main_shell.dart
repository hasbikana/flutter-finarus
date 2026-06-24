import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../utils/format.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/ocr_provider.dart';
import '../widgets/glass_card.dart';
import '../services/share_intent_service.dart';
import '../services/share_file_resolver.dart';
import '../services/notif_capture_handler.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'accounts_screen.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'savings_screen.dart';
import 'notifications_screen.dart';
import 'parse_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _shareHandler = ShareIntentService();
  final _notifCapture = NotifCaptureHandler();

  final _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _shareHandler.listen((data) async => await _processShareData(data));
    _shareHandler.getInitialMedia((data) async => await _processShareData(data));
    _notifCapture.start(getToken: () => context.read<AuthProvider>().token);
  }

  @override
  void dispose() {
    _shareHandler.dispose();
    _notifCapture.stop();
    super.dispose();
  }

  Future<void> _processShareData(ShareIntentData data) async {
    if (!mounted) {
      debugPrint('[MainShell] _processShareData: not mounted');
      return;
    }

    debugPrint('[MainShell] _processShareData: $data');

    if (data.isText) {
      final text = data.text!;
      debugPrint('[MainShell] Processing text (${text.length} chars): ${text.length > 100 ? "${text.substring(0, 100)}..." : text}');
      context.read<OcrProvider>().processText(text);
      _openParseScreen();
    } else if (data.isImage) {
      debugPrint('[MainShell] Resolving shared image: ${data.imagePath}');
      final resolvedPath = await ShareFileResolver.resolve(data.imagePath!);
      if (resolvedPath == null) {
        debugPrint('[MainShell] Failed to resolve shared image');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membaca gambar yang dibagikan')),
          );
        }
        return;
      }
      debugPrint('[MainShell] Processing resolved image: $resolvedPath');
      if (mounted) {
        context.read<OcrProvider>().processImagePath(resolvedPath);
        _openParseScreen();
      }
    }
  }

  void _openParseScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParseScreen()),
    );
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openAddTransaction() {
    final cat = context.read<CategoryProvider>();
    final acc = context.read<AccountProvider>();
    if (cat.categories.isEmpty) cat.loadCategories();
    if (acc.accounts.isEmpty) acc.loadAccounts();
    setState(() => _currentIndex = 1);
    Future.microtask(() {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _QuickTransactionForm(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: FinarusColors.backgroundTop,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const _AppBarGreeting(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.document_scanner_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParseScreen()),
                    );
                  },
                ),
                _NotificationBadge(),
              ],
            )
          : null,
      drawer: NavigationDrawer(
        backgroundColor: FinarusColors.background,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index < 4) {
            setState(() => _currentIndex = index);
            Navigator.pop(context);
          } else {
            Navigator.pop(context);
            final screens = [
              const AccountsScreen(),
              const BudgetsScreen(),
              const CategoriesScreen(),
              const SavingsScreen(),
            ];
            _openScreen(screens[index - 4]);
          }
        },
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: FinarusColors.linear(FinarusColors.gradientCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Finarus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Kelola Keuanganmu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: const Text('Beranda'),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: const Icon(Icons.swap_horiz),
            label: const Text('Transaksi'),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: const Text('Laporan'),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: const Text('Akun'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Manajemen',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: const Text('Dompet'),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: const Text('Anggaran'),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: const Text('Kategori'),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: const Icon(Icons.savings),
            label: const Text('Tabungan'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          top: false,
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: FinarusColors.gradientCard,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: FinarusColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: FinarusColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: FinarusColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: FinarusColors.cardShadow.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(-4, -4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Beranda',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _BottomNavItem(
                  icon: Icons.swap_horiz_outlined,
                  activeIcon: Icons.swap_horiz,
                  label: 'Transaksi',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                const SizedBox(width: 60),
                _BottomNavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Laporan',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _BottomNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Akun',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? FinarusColors.primary : const Color(0xFF94A3B8);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isActive
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: FinarusColors.gradientCard,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(activeIcon, color: Colors.white, size: 20),
                  )
                : Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider>().totalUnreadCount;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: GlassIconButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Icons.notifications_outlined,
            iconColor: FinarusColors.foreground,
            backgroundColor: FinarusColors.card,
            size: 44,
          ),
        ),
        if (count > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _AppBarGreeting extends StatelessWidget {
  const _AppBarGreeting();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 11) {
      greeting = 'Selamat pagi';
    } else if (hour < 15) {
      greeting = 'Selamat siang';
    } else if (hour < 19) {
      greeting = 'Selamat sore';
    } else {
      greeting = 'Selamat malam';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 11,
            color: FinarusColors.mutedFg,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          auth.user?.name ?? 'Pengguna',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FinarusColors.foreground,
          ),
        ),
      ],
    );
  }
}

// Quick Transaction Form tetap sama seperti sebelumnya
class _QuickTransactionForm extends StatefulWidget {
  const _QuickTransactionForm();

  @override
  State<_QuickTransactionForm> createState() => _QuickTransactionFormState();
}

class _QuickTransactionFormState extends State<_QuickTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'expense';
  int? _categoryId;
  int? _accountId;
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null || _accountId == null) return;
    setState(() => _isSubmitting = true);

    final body = {
      'type': _type,
      'amount': _amountController.text,
      'description': _descriptionController.text,
      'transaction_date': _date.toIso8601String().split('T').first,
      'category_id': _categoryId,
      'account_id': _accountId,
    };

    final success = await context.read<TransactionProvider>().createTransaction(body);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<TransactionProvider>().error ?? 'Gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final accounts = context.watch<AccountProvider>().accounts;
    final incomeCats = categories.where((c) => c.type == 'income' || c.type == 'both').toList();
    final expenseCats = categories.where((c) => c.type == 'expense' || c.type == 'both').toList();
    final filteredCats = _type == 'income' ? incomeCats : expenseCats;
    final allAccounts = accounts.toList();

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: FinarusColors.gradientCard,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tambah Transaksi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: FinarusColors.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                    ButtonSegment(value: 'income', label: Text('Pemasukan')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null) return 'Angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                items: filteredCats.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.icon ?? ''} ${c.name}'),
                )).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Akun',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                items: allAccounts.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name),
                )).toList(),
                onChanged: (v) => setState(() => _accountId = v),
                validator: (v) => v == null ? 'Pilih akun' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                  ),
                  child: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(height: 24),
              GlassButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Tambah Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
