import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/saving_goal_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../models/saving_goal.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/glass_card.dart';
import '../utils/format.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingGoalProvider>().loadGoals();
      context.read<CategoryProvider>().loadCategories();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sg = context.watch<SavingGoalProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tabungan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: sg.isLoading
            ? const Center(child: CircularProgressIndicator())
            : sg.goals.isEmpty
                ? const EmptyState(message: 'Belum ada tabungan')
                : RefreshIndicator(
                    onRefresh: () => sg.loadGoals(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sg.goals.length,
                      itemBuilder: (ctx, i) {
                        final g = sg.goals[i];
                        return _GoalCard(
                          goal: g,
                          onAddFund: () => _addFund(ctx, g),
                          onEdit: () => _showForm(ctx, g),
                          onDelete: () => _confirmDelete(ctx, g.id),
                        );
                      },
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

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tabungan'),
        content: const Text('Yakin ingin menghapus tabungan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SavingGoalProvider>().deleteGoal(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addFund(BuildContext context, SavingGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        borderRadius: 24,
        child: _AddFundForm(goal: goal),
      ),
    );
  }

  void _showForm(BuildContext context, [SavingGoal? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        borderRadius: 24,
        child: _SavingGoalForm(existing: existing),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingGoal goal;
  final VoidCallback onAddFund;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddFund,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gradColors = goal.progress >= 75
        ? FinarusColors.gradientGreen
        : goal.progress >= 50
            ? FinarusColors.gradientBlue
            : FinarusColors.gradientOrange;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradColors),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(goal.icon ?? '🎯', style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: FinarusColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (goal.deadline != null)
                      Text(
                        'Target: ${formatDate(goal.deadline!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: FinarusColors.mutedFg,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton(
                iconSize: 20,
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: const ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Edit')),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: const ListTile(leading: Icon(Icons.delete, size: 20, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProgressBar(
            progress: goal.progress,
            gradient: gradColors,
            height: 10,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${goal.progress.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: FinarusColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(goal.currentAmount),
                style: TextStyle(fontSize: 13, color: FinarusColors.mutedFg),
              ),
              const Text(' / ', style: TextStyle(color: FinarusColors.mutedFg)),
              Text(
                formatRupiah(goal.targetAmount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: FinarusColors.foreground,
                ),
              ),
            ],
          ),
          if (goal.remaining > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Sisa: ${formatRupiah(goal.remaining)}',
              style: TextStyle(
                fontSize: 12,
                color: FinarusColors.mutedFg,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              onPressed: onAddFund,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 6),
                  Text('Tambah Dana'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFundForm extends StatefulWidget {
  final SavingGoal goal;

  const _AddFundForm({required this.goal});

  @override
  State<_AddFundForm> createState() => _AddFundFormState();
}

class _AddFundFormState extends State<_AddFundForm> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  int? _accountId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _accountId == null) return;

    setState(() => _isSubmitting = true);

    final body = {
      'type': 'expense',
      'amount': _controller.text,
      'description': 'Tabungan: ${widget.goal.name}',
      'transaction_date': DateTime.now().toIso8601String().split('T').first,
      'saving_goal_id': widget.goal.id,
      'category_id': _findSavingCategoryId(),
      'account_id': _accountId,
    };

    final success = await context.read<TransactionProvider>().createTransaction(body);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      context.read<SavingGoalProvider>().loadGoals();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dana berhasil ditambahkan')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambah dana')),
      );
    }
  }

  int _findSavingCategoryId() {
    final cats = context.read<CategoryProvider>().categories;
    for (final c in cats) {
      if (c.name.toLowerCase() == 'tambah tabungan') return c.id;
    }
    for (final c in cats) {
      if (c.type == 'expense' || c.type == 'both') return c.id;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tambah Dana: ${widget.goal.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Masukkan angka valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Akun',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                items: (context.watch<AccountProvider>().accounts.toList())
                    .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.name),
                    )).toList(),
                onChanged: (v) => setState(() => _accountId = v),
                validator: (v) => v == null ? 'Pilih akun' : null,
              ),
              const SizedBox(height: 16),
              LoadingButton(
                isLoading: _isSubmitting,
                label: 'Tambah Dana',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingGoalForm extends StatefulWidget {
  final SavingGoal? existing;

  const _SavingGoalForm({this.existing});

  @override
  State<_SavingGoalForm> createState() => _SavingGoalFormState();
}

class _SavingGoalFormState extends State<_SavingGoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  String? _icon;
  DateTime? _deadline;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _targetController.text = e.targetAmount.toStringAsFixed(0);
      _icon = e.icon;
      _deadline = e.deadline;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final body = {
      'name': _nameController.text,
      'target_amount': _targetController.text,
      'icon': _icon ?? '🎯',
      if (_deadline != null)
        'deadline': _deadline!.toIso8601String().split('T').first,
    };

    final provider = context.read<SavingGoalProvider>();
    final success = widget.existing != null
        ? await provider.updateGoal(widget.existing!.id, body)
        : await provider.createGoal(body);

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
                widget.existing != null ? 'Edit Tabungan' : 'Tambah Tabungan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Tabungan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target (Rp)',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Masukkan angka valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDeadline,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Target Tanggal (opsional)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    _deadline != null ? formatDate(_deadline!) : 'Belum dipilih',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pilih Icon', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              EmojiPicker(
                selectedEmoji: _icon,
                onEmojiSelected: (e) => setState(() => _icon = e),
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
