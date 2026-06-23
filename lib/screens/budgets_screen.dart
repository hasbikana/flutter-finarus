import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../models/budget.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_button.dart';
import '../utils/format.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BudgetProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Anggaran'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _pickMonthYear(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: FinarusColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        formatMonthYear(bp.selectedMonth, bp.selectedYear),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: FinarusColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: bp.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : bp.budgets.isEmpty
                        ? const EmptyState(message: 'Belum ada anggaran bulan ini')
                        : RefreshIndicator(
                            onRefresh: () => bp.loadBudgets(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: bp.budgets.length,
                              itemBuilder: (ctx, i) {
                                final b = bp.budgets[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _BudgetCard(
                                    budget: b,
                                    onEdit: () => _showForm(ctx, b),
                                    onDelete: () => _confirmDelete(ctx, b.id),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void _pickMonthYear(BuildContext context) async {
    final bp = context.read<BudgetProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(bp.selectedYear, bp.selectedMonth),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Pilih Bulan & Tahun',
    );
    if (picked != null) {
      bp.setMonth(picked.month);
      bp.setYear(picked.year);
    }
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Anggaran'),
        content: const Text('Yakin ingin menghapus anggaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BudgetProvider>().deleteBudget(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, [Budget? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BudgetForm(existing: existing),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: budget.isOverBudget
                                ? FinarusColors.expense.withValues(alpha: 0.1)
                                : FinarusColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(budget.category?.icon ?? '📊', style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            budget.category?.name ?? 'Kategori',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: FinarusColors.foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${formatRupiah(budget.spent)} / ${formatRupiah(budget.amount)}',
                      style: TextStyle(
                        color: FinarusColors.mutedFg,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${budget.progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: budget.isOverBudget ? FinarusColors.expense : FinarusColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (budget.isOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: FinarusColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Over Budget!',
                        style: TextStyle(
                          color: FinarusColors.expense,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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

class _BudgetForm extends StatefulWidget {
  final Budget? existing;

  const _BudgetForm({this.existing});

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  int? _categoryId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _categoryId = e.categoryId;
      _amountController.text = e.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;

    setState(() => _isSubmitting = true);

    final bp = context.read<BudgetProvider>();
    final body = {
      'category_id': _categoryId,
      'amount': _amountController.text,
      'month': bp.selectedMonth,
      'year': bp.selectedYear,
    };

    final success = widget.existing != null
        ? await bp.updateBudget(widget.existing!.id, body)
        : await bp.createBudget(body);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bp.error ?? 'Gagal menyimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories
        .where((c) => c.type == 'expense' || c.type == 'both')
        .toList();

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
                widget.existing != null ? 'Edit Anggaran' : 'Tambah Anggaran',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.icon ?? ''} ${c.name}'),
                )).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Batas Anggaran (Rp)',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Masukkan angka valid';
                  }
                  return null;
                },
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
