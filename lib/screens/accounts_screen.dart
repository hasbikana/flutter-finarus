import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_button.dart';
import '../utils/format.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _logoOptions = [
    'bca', 'mandiri', 'bni', 'bri', 'cimb', 'danamon', 'permata',
    'gopay', 'ovo', 'dana', 'shopeepay', 'linkaja',
    'visa', 'mastercard', 'cash',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AccountProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Dompet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: ap.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ap.accounts.isEmpty
                ? const EmptyState(message: 'Belum ada akun')
                : RefreshIndicator(
                    onRefresh: () => ap.loadAccounts(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      children: [
                        GlassCard(
                          borderRadius: 20,
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: FinarusColors.gradientTeal,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Saldo',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatRupiah(ap.totalBalance),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${ap.totalAccounts} akun',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (ap.cashAccount != null)
                          _AccountGroup(
                            title: 'Tunai',
                            accounts: [ap.cashAccount!],
                          ),
                        if (ap.bankAccounts.isNotEmpty)
                          _AccountGroup(title: 'Bank', accounts: ap.bankAccounts),
                        if (ap.ewalletAccounts.isNotEmpty)
                          _AccountGroup(title: 'E-Wallet', accounts: ap.ewalletAccounts),
                        if (ap.creditCardAccounts.isNotEmpty)
                          _AccountGroup(title: 'Kartu Kredit', accounts: ap.creditCardAccounts),
                      ],
                    ),
                  ),
                ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: FinarusColors.gradientBlue,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: FinarusColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showForm(BuildContext context, [Account? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AccountForm(existing: existing, logoOptions: _logoOptions),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  final String title;
  final List<Account> accounts;

  const _AccountGroup({required this.title, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: FinarusColors.mutedFg,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...accounts.map((a) => GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: a.type == 'bank'
                        ? FinarusColors.gradientBlue
                        : a.type == 'ewallet'
                            ? FinarusColors.gradientOrange
                            : a.type == 'credit_card'
                                ? FinarusColors.gradientPink
                                : FinarusColors.gradientGreen,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: a.logo != null
                      ? Text(
                          a.logo![0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : Icon(
                          a.type == 'bank'
                              ? Icons.account_balance
                              : a.type == 'ewallet'
                                  ? Icons.phone_android
                                  : Icons.credit_card,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: FinarusColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.accountNumber != null
                          ? '${a.provider} • ${a.accountNumber}'
                          : a.provider,
                      style: const TextStyle(
                        color: FinarusColors.mutedFg,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupiah(a.balance),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: FinarusColors.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (a.balance > 0)
                    Text(
                      a.type == 'credit_card' ? 'Terpakai' : 'Tersedia',
                      style: const TextStyle(
                        color: FinarusColors.mutedFg,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _AccountForm extends StatefulWidget {
  final Account? existing;
  final List<String> logoOptions;

  const _AccountForm({this.existing, required this.logoOptions});

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _providerController = TextEditingController();
  final _numberController = TextEditingController();
  final _balanceController = TextEditingController();

  String _type = 'bank';
  String? _logo;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _providerController.text = e.provider;
      _numberController.text = e.accountNumber ?? '';
      _balanceController.text = e.balance.toStringAsFixed(0);
      _type = e.type;
      _logo = e.logo;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _numberController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final body = {
      'name': _nameController.text,
      'provider': _providerController.text,
      'type': _type,
      'account_number': _numberController.text,
      'balance': _balanceController.text.isNotEmpty
          ? double.parse(_balanceController.text)
          : 0,
      if (_logo != null) 'logo': _logo,
    };

    final provider = context.read<AccountProvider>();
    final success = widget.existing != null
        ? await provider.updateAccount(widget.existing!.id, body)
        : await provider.createAccount(body);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Gagal menyimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing != null ? 'Edit Akun' : 'Tambah Akun',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Akun',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _providerController,
                decoration: const InputDecoration(
                  labelText: 'Penyedia (contoh: BCA, GoPay)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'bank', label: Text('Bank')),
                  ButtonSegment(value: 'ewallet', label: Text('E-Wallet')),
                  ButtonSegment(value: 'credit_card', label: Text('Kartu Kredit')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Akun (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal (Rp)',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pilih Logo', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.logoOptions.map((logo) {
                  final isSelected = _logo == logo;
                  return GestureDetector(
                    onTap: () => setState(() => _logo = logo),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? FinarusColors.primary.withValues(alpha: 0.1)
                            : FinarusColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: FinarusColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          logo[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? FinarusColors.primary : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                isLoading: _isSubmitting,
                label: widget.existing != null ? 'Simpan' : 'Tambah',
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
