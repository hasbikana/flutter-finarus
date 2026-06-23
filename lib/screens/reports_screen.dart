import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import '../config/colors.dart';
import '../providers/report_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../utils/format.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FinarusColors.foreground,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _pickMonthYear(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (format) => _export(context, format),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinarusColors.bgGradient(),
        ),
        child: SafeArea(
          child: rp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : rp.monthlyReport == null
                  ? const EmptyState(message: 'Gagal memuat laporan')
                  : RefreshIndicator(
                      onRefresh: () => rp.loadReports(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        Text(
                          formatMonthYear(rp.selectedMonth, rp.selectedYear),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: FinarusColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryGlassCard(
                                title: 'Pemasukan',
                                amount: rp.monthlyReport!.totalIncome,
                                icon: Icons.arrow_upward,
                                color: FinarusColors.income,
                                bgColor: FinarusColors.incomeLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryGlassCard(
                                title: 'Pengeluaran',
                                amount: rp.monthlyReport!.totalExpense,
                                icon: Icons.arrow_downward,
                                color: FinarusColors.expense,
                                bgColor: FinarusColors.expenseLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryGlassCard(
                                title: 'Saldo',
                                amount: rp.monthlyReport!.balance,
                                icon: Icons.account_balance_wallet_outlined,
                                color: FinarusColors.primary,
                                bgColor: FinarusColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (rp.categoryReport != null && rp.categoryReport!.categories.isNotEmpty) ...[
                          const Text(
                            'Pengeluaran per Kategori',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: FinarusColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(20),
                            child: SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  sections: rp.categoryReport!.categories.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final cat = entry.value;
                                    final colors = [
                                      FinarusColors.chartBlue,
                                      FinarusColors.chartRed,
                                      FinarusColors.chartGreen,
                                      FinarusColors.chartOrange,
                                      FinarusColors.chartPurple,
                                      FinarusColors.chartYellow,
                                    ];
                                    return PieChartSectionData(
                                      value: cat.total,
                                      color: colors[i % colors.length],
                                      radius: 70,
                                      title: '${cat.categoryName}\n${formatRupiah(cat.total)}',
                                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  }).toList(),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 35,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...rp.categoryReport!.categories.map((cat) {
                            final total = rp.categoryReport!.categories.fold<double>(
                              0, (sum, c) => sum + c.total,
                            );
                            final pct = total > 0 ? (cat.total / total * 100) : 0.0;
                            return GlassCard(
                              borderRadius: 16,
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        (cat.categoryColor != null
                                            ? int.tryParse(cat.categoryColor!.replaceFirst('#', '0xFF'))
                                            : 0xFF64748B) ?? 0xFF64748B,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${cat.categoryIcon ?? ''} ${cat.categoryName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: FinarusColors.foreground,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${pct.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: FinarusColors.mutedFg,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    formatRupiah(cat.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: FinarusColors.foreground,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 24),
                        if (rp.trendReport != null && rp.trendReport!.trend.isNotEmpty) ...[
                          const Text(
                            'Tren Tahunan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: FinarusColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(20),
                            child: SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: rp.trendReport!.trend.fold<double>(0, (max, t) => max > t.income ? max : t.income) * 1.2,
                                  barGroups: rp.trendReport!.trend.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final t = entry.value;
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: t.income,
                                          color: FinarusColors.chartGreen,
                                          width: 8,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                        BarChartRodData(
                                          toY: t.expense,
                                          color: FinarusColors.chartRed,
                                          width: 8,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final i = value.toInt();
                                          if (i >= 0 && i < rp.trendReport!.trend.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                rp.trendReport!.trend[i].monthName.substring(0, 3),
                                                style: const TextStyle(fontSize: 10, color: FinarusColors.mutedFg),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barTouchData: BarTouchData(enabled: false),
                                  gridData: FlGridData(show: false),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LegendItem(color: FinarusColors.chartGreen, label: 'Pemasukan'),
                              const SizedBox(width: 24),
                              _LegendItem(color: FinarusColors.chartRed, label: 'Pengeluaran'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
    );
  }

  void _pickMonthYear(BuildContext context) async {
    final rp = context.read<ReportProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(rp.selectedYear, rp.selectedMonth),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Pilih Bulan & Tahun',
    );
    if (picked != null) {
      rp.setMonth(picked.month);
      rp.setYear(picked.year);
    }
  }

  Future<void> _export(BuildContext context, String format) async {
    final rp = context.read<ReportProvider>();
    final file = await rp.downloadExport(format);
    if (file != null && mounted) {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Laporan tersimpan: ${file.path}')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rp.error ?? 'Gagal export')),
      );
    }
  }
}

class _SummaryGlassCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SummaryGlassCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: FinarusColors.mutedFg,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatRupiah(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: FinarusColors.foreground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: FinarusColors.mutedFg)),
      ],
    );
  }
}
