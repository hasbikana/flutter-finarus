import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../widgets/color_picker.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/glass_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CategoryProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Kategori'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: cat.isLoading
            ? const Center(child: CircularProgressIndicator())
            : cat.categories.isEmpty
                ? const EmptyState(message: 'Belum ada kategori')
                : RefreshIndicator(
                    onRefresh: () => cat.loadCategories(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: cat.categories.length,
                      itemBuilder: (ctx, i) {
                        final c = cat.categories[i];
                        return _CategoryCard(
                          category: c,
                          onEdit: () => _showForm(ctx, c),
                          onDelete: () => _confirmDelete(ctx, c.id),
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
        title: const Text('Hapus Kategori'),
        content: const Text('Yakin ingin menghapus kategori ini? Transaksi terkait juga akan terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CategoryProvider>().deleteCategory(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, [Category? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        borderRadius: 24,
        child: _CategoryForm(existing: existing),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorHex = category.color ?? '#64748B';
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        onLongPress: onDelete,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                category.icon ?? '📁',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: FinarusColors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              category.type.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: FinarusColors.mutedFg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryForm extends StatefulWidget {
  final Category? existing;

  const _CategoryForm({this.existing});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _type = 'expense';
  String? _icon;
  String? _color;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _type = e.type;
      _icon = e.icon;
      _color = e.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final body = {
      'name': _nameController.text,
      'type': _type,
      'icon': _icon ?? '📁',
      'color': _color ?? '#64748B',
    };

    final provider = context.read<CategoryProvider>();
    final success = widget.existing != null
        ? await provider.updateCategory(widget.existing!.id, body)
        : await provider.createCategory(body);

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
                widget.existing != null ? 'Edit Kategori' : 'Tambah Kategori',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'income', label: Text('Pemasukan')),
                  ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                  ButtonSegment(value: 'both', label: Text('Keduanya')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 16),
              Text('Pilih Icon', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              EmojiPicker(
                selectedEmoji: _icon,
                onEmojiSelected: (e) => setState(() => _icon = e),
              ),
              const SizedBox(height: 16),
              Text('Pilih Warna', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              ColorPicker(
                selectedColor: _color,
                onColorSelected: (c) => setState(() => _color = c),
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
