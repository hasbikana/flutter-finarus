import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/colors.dart';
import '../providers/ocr_provider.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/glass_card.dart';
import '../utils/format.dart';

class ParseScreen extends StatefulWidget {
  const ParseScreen({super.key});

  @override
  State<ParseScreen> createState() => _ParseScreenState();
}

class _ParseScreenState extends State<ParseScreen> {
  String _type = 'expense';
  double _amount = 0;
  String _merchant = '';
  String _description = '';
  int? _categoryId;
  int? _accountId;
  bool _submitting = false;
  bool _editing = false;

  TextEditingController _amountController = TextEditingController();
  TextEditingController _merchantController = TextEditingController();
  TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final ocr = context.read<OcrProvider>();
    if (ocr.ocrResult != null) {
      final r = ocr.ocrResult!;
      setState(() {
        _type = 'expense';
        _amount = r.totalAmount ?? 0;
        _merchant = r.merchant ?? '';
        _syncControllers();
      });
    } else if (ocr.notifResult != null) {
      final r = ocr.notifResult!;
      setState(() {
        _type = r.type;
        _amount = r.amount;
        _merchant = r.merchant ?? '';
        _syncControllers();
      });
    }
    FocusScope.of(context).unfocus();
  }

  void _syncControllers() {
    _amountController.text = _amount > 0 ? _amount.toStringAsFixed(0) : '';
    _merchantController.text = _merchant;
    _descController.text = _description;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickCamera() async {
    await context.read<OcrProvider>().pickAndProcessImage(ImageSource.camera);
    if (mounted) _loadData();
  }

  Future<void> _pickGallery() async {
    await context.read<OcrProvider>().pickAndProcessImage(ImageSource.gallery);
    if (mounted) _loadData();
  }

  Future<void> _submit() async {
    if (_categoryId == null || _accountId == null || _amount <= 0) return;

    setState(() => _submitting = true);

    final ocr = context.read<OcrProvider>();
    final success = await ocr.submitPending(
      categoryId: _categoryId!,
      accountId: _accountId!,
      description: _descController.text.isNotEmpty ? _descController.text : null,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil dikirim ke pending')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ocr.error ?? 'Gagal menyimpan')),
        );
      }
    }
  }

  void _reset() {
    context.read<OcrProvider>().reset();
    setState(() {
      _type = 'expense';
      _amount = 0;
      _merchant = '';
      _description = '';
      _categoryId = null;
      _accountId = null;
      _editing = false;
      _syncControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ocr = context.watch<OcrProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final accounts = context.watch<AccountProvider>().accounts;
    final filteredCats = categories.where((c) => c.type == _type || c.type == 'both').toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_editing ? 'Edit Transaksi' : 'Hasil Deteksi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
        actions: [
          if (_amount > 0 || _merchant.isNotEmpty)
            TextButton(
              onPressed: _reset,
              child: const Text('Batal', style: TextStyle(color: Colors.red)),
            ),
          if (!_editing && (_amount > 0 || _merchant.isNotEmpty))
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: FinarusColors.bgGradient()),
        child: SafeArea(
          child: ocr.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (ocr.ocrResult != null || ocr.notifResult != null) ...[
                        _buildResultCard(),
                        const SizedBox(height: 20),
                        if (!_editing) ...[
                          _buildImagePreview(ocr),
                          const SizedBox(height: 20),
                        ],
                      ] else ...[
                        _buildEmptyState(),
                      ],
                      if (_editing || _amount == 0) ...[
                        _buildFormSection(filteredCats, accounts),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _editing ? null : (context.read<OcrProvider>().ocrResult ?? context.read<OcrProvider>().notifResult);
    if (r == null && !_editing) return const SizedBox.shrink();

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _type == 'income'
                      ? FinarusColors.income.withValues(alpha: 0.1)
                      : FinarusColors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _type == 'income' ? FinarusColors.income : FinarusColors.expense,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                      style: TextStyle(
                        fontSize: 13,
                        color: FinarusColors.mutedFg,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _amount > 0 ? formatRupiah(_amount) : 'Rp 0',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _type == 'income' ? FinarusColors.income : FinarusColors.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_merchant.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FinarusColors.secondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.store, size: 16, color: FinarusColors.mutedFg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _merchant,
                      style: const TextStyle(
                        fontSize: 14,
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
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(OcrProvider ocr) {
    if (ocr.image == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(ocr.image!.path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.document_scanner, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text(
          'Pilih sumber untuk mendeteksi transaksi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _pickCamera,
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: FinarusColors.primary),
                      const SizedBox(height: 8),
                      const Text('Kamera'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _pickGallery,
                  child: Column(
                    children: [
                      Icon(Icons.photo_library, size: 40, color: FinarusColors.chartOrange),
                      const SizedBox(height: 8),
                      const Text('Galeri'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FinarusColors.mutedFg,
                  side: BorderSide(color: FinarusColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Ulangi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                onPressed: _editing ? null : () => setState(() => _editing = true),
                child: const Text('Lanjut'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection(List categories, List accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
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
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Jumlah (Rp)',
            prefixIcon: const Icon(Icons.monetization_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
          ),
          onChanged: (v) => _amount = double.tryParse(v.replaceAll('.', '')) ?? 0,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _merchantController,
          decoration: InputDecoration(
            labelText: 'Merchant / Toko',
            prefixIcon: const Icon(Icons.store),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
          ),
          onChanged: (v) => _merchant = v,
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
          maxLines: 2,
          onChanged: (v) => _description = v,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Kategori',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: FinarusColors.secondary.withValues(alpha: 0.5),
          ),
          items: categories.map((c) => DropdownMenuItem<int>(
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
          items: accounts.map((a) => DropdownMenuItem<int>(
            value: a.id,
            child: Text(a.name),
          )).toList(),
          onChanged: (v) => setState(() => _accountId = v),
          validator: (v) => v == null ? 'Pilih akun' : null,
        ),
        const SizedBox(height: 24),
        GlassButton(
          onPressed: (_categoryId == null || _accountId == null || _amount <= 0 || _submitting)
              ? null
              : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Kirim ke Pending'),
        ),
      ],
    );
  }
}