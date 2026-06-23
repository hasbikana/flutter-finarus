import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_button.dart';
import '../utils/format.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<CategoryProvider>().loadCategories();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    hintStyle: TextStyle(color: FinarusColors.mutedFg),
                    prefixIcon: Icon(Icons.search, size: 20, color: FinarusColors.mutedFg),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    filled: false,
                  ),
                  style: TextStyle(color: FinarusColors.foreground),
                  onSubmitted: (v) => tx.setSearchQuery(v.isEmpty ? null : v),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: FinarusColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SegmentedButton<String?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('Semua')),
                    ButtonSegment(value: 'income', label: Text('Pemasukan')),
                    ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                  ],
                  selected: {tx.typeFilter},
                  onSelectionChanged: (v) => tx.setTypeFilter(v.first),
                ),
              ),
            ),
            Expanded(
              child: tx.isLoading && tx.transactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : tx.transactions.isEmpty
                      ? const EmptyState(message: 'Belum ada transaksi')
                      : RefreshIndicator(
                          onRefresh: () => tx.loadTransactions(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: tx.transactions.length + (tx.hasMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == tx.transactions.length) {
                                tx.loadTransactions(loadMore: true);
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final t = tx.transactions[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TransactionTile(
                                  transaction: t,
                                  onEdit: () => _showForm(ctx, t),
                                  onDelete: () => _confirmDelete(ctx, t.id),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: FinarusColors.gradientCard,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: FinarusColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionProvider>().deleteTransaction(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, [Transaction? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TransactionForm(existing: existing),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final iconColor = isIncome ? FinarusColors.income : FinarusColors.expense;
    return GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: iconColor, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category?.name ?? transaction.description ?? 'Transaksi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: FinarusColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          formatDate(transaction.transactionDate),
                          style: TextStyle(
                            color: FinarusColors.mutedFg,
                            fontSize: 12,
                          ),
                        ),
                        if (transaction.description != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '• ${transaction.description}',
                              style: TextStyle(
                                color: FinarusColors.mutedFg,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton(
                iconSize: 20,
                icon: Icon(Icons.more_vert, color: FinarusColors.mutedFg),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: const ListTile(
                      leading: Icon(Icons.edit, size: 20), title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: const ListTile(
                      leading: Icon(Icons.delete, size: 20, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionForm extends StatefulWidget {
  final Transaction? existing;

  const _TransactionForm({this.existing});

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  int? _categoryId;
  int? _accountId;
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _type = e.type;
      _categoryId = e.categoryId;
      _accountId = e.accountId;
      _date = e.transactionDate;
      _amountController.text = e.amount.toStringAsFixed(0);
      _descriptionController.text = e.description ?? '';
    }
  }

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

    final provider = context.read<TransactionProvider>();
    final success = widget.existing != null
        ? await provider.updateTransaction(widget.existing!.id, body)
        : await provider.createTransaction(body);

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
    final categories = context.watch<CategoryProvider>().categories;
    final accounts = context.watch<AccountProvider>().accounts;
    final incomeCategories = categories.where((c) => c.type == 'income' || c.type == 'both').toList();
    final expenseCategories = categories.where((c) => c.type == 'expense' || c.type == 'both').toList();
    final filteredCategories = _type == 'income' ? incomeCategories : expenseCategories;
    final allAccounts = accounts.toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing != null ? 'Edit Transaksi' : 'Tambah Transaksi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                  ButtonSegment(value: 'income', label: Text('Pemasukan')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() {
                  _type = v.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null) return 'Angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: filteredCategories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.icon ?? ''} ${c.name}'),
                )).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _accountId,
                decoration: const InputDecoration(
                  labelText: 'Akun',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatDate(_date)),
                ),
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
