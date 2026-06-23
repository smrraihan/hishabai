import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/receipt.dart';
import '../services/receipt_store.dart';
import '../theme/app_theme.dart';
import 'receipt_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.store,
    required this.onAddReceipt,
    required this.onSeeAll,
  });

  final GoogleSignInAccount user;
  final ReceiptStore store;
  final VoidCallback onAddReceipt;
  final VoidCallback onSeeAll;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user.displayName?.split(' ').first ?? 'there';
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final months = _monthOptions(widget.store.receipts);
          final selectedMonth = months.contains(_selectedMonth)
              ? _selectedMonth
              : (months.isEmpty ? null : months.first);
          final chartReceipts = selectedMonth == null
              ? <Receipt>[]
              : widget.store.receipts
                    .where((receipt) => _monthKey(receipt) == selectedMonth)
                    .toList();
          final categoryTotals = _categoryTotals(chartReceipts);

          return RefreshIndicator(
            onRefresh: widget.store.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/hishabAI_logo.png', width: 42),
                    const SizedBox(width: 12),
                    Text(
                      'hishabAI',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    CircleAvatar(
                      backgroundColor: AppColors.paleGold,
                      backgroundImage: widget.user.photoUrl == null
                          ? null
                          : NetworkImage(widget.user.photoUrl!),
                      child: widget.user.photoUrl == null
                          ? Text(_initials(widget.user.displayName))
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome back, $firstName',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Capture and organize your receipts.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved receipts',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.store.receipts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Private to your Google account',
                        style: TextStyle(color: Color(0xFF8BE0B7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.camera_alt_outlined,
                        label: 'Add receipt',
                        color: AppColors.paleCoral,
                        onTap: widget.onAddReceipt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'My receipts',
                        color: AppColors.paleGold,
                        onTap: widget.onSeeAll,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _CategoryChartCard(
                  selectedMonth: selectedMonth,
                  months: months,
                  totals: categoryTotals,
                  onMonthChanged: (value) => setState(() {
                    _selectedMonth = value;
                  }),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      'Recent transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onSeeAll,
                      child: const Text('See all'),
                    ),
                  ],
                ),
                if (widget.store.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!widget.store.loading && widget.store.receipts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Your saved receipts will appear here.'),
                    ),
                  ),
                ...widget.store.receipts
                    .take(3)
                    .map(
                      (receipt) => _TransactionTile(
                        receipt: receipt,
                        onTap: () => _openReceiptDetail(context, receipt),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openReceiptDetail(BuildContext context, Receipt receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReceiptDetailScreen(receipt: receipt, store: widget.store),
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.receipt, required this.onTap});
  final Receipt receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: const CircleAvatar(
        backgroundColor: AppColors.canvas,
        child: Icon(Icons.receipt_long_outlined, color: AppColors.ink),
      ),
      title: Text(
        receipt.merchantName.isEmpty
            ? 'Unknown merchant'
            : receipt.merchantName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${receipt.category} · ${receipt.transactionDate}'),
      trailing: Text(
        receipt.amount,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _CategoryChartCard extends StatelessWidget {
  const _CategoryChartCard({
    required this.selectedMonth,
    required this.months,
    required this.totals,
    required this.onMonthChanged,
  });

  final String? selectedMonth;
  final List<String> months;
  final Map<String, double> totals;
  final ValueChanged<String?> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final slices = _categorySlices(totals);
    final total = totals.values.fold<double>(0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Category expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedMonth,
                  hint: const Text('Month'),
                  items: months
                      .map(
                        (month) => DropdownMenuItem(
                          value: month,
                          child: Text(_monthLabel(month)),
                        ),
                      )
                      .toList(),
                  onChanged: months.isEmpty ? null : onMonthChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (slices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('No category data for this month yet.'),
              )
            else ...[
              Row(
                children: [
                  SizedBox(
                    width: 142,
                    height: 142,
                    child: CustomPaint(
                      painter: _PieChartPainter(slices),
                      child: Center(
                        child: Text(
                          _money(total),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: slices
                          .map(
                            (slice) => _LegendRow(
                              label: slice.category,
                              amount: slice.amount,
                              color: slice.color,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(_money(amount), style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter(this.slices);

  final List<_CategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.amount);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.amount / total) * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(rect.deflate(4), start, sweep, true, paint);
      start += sweep;
    }

    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.28,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _CategorySlice {
  const _CategorySlice({
    required this.category,
    required this.amount,
    required this.color,
  });

  final String category;
  final double amount;
  final Color color;
}

List<String> _monthOptions(List<Receipt> receipts) {
  final months = receipts.map(_monthKey).whereType<String>().toSet().toList();
  months.sort((a, b) => b.compareTo(a));
  return months;
}

String? _monthKey(Receipt receipt) {
  final date = _receiptDate(receipt);
  if (date == null) return null;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}

DateTime? _receiptDate(Receipt receipt) {
  final uploadedAt = DateTime.tryParse(receipt.uploadedAt);
  final transactionDate = _parseTransactionDate(receipt.transactionDate);
  return transactionDate ?? uploadedAt;
}

DateTime? _parseTransactionDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return iso;

  final match = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$',
  ).firstMatch(trimmed);
  if (match == null) return null;
  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  var year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  return DateTime(year, month, day);
}

Map<String, double> _categoryTotals(List<Receipt> receipts) {
  final totals = <String, double>{};
  for (final receipt in receipts) {
    final amount = _parseAmount(receipt.amount);
    if (amount <= 0) continue;
    final category = receipt.category.trim().isEmpty
        ? 'Other'
        : receipt.category.trim();
    totals[category] = (totals[category] ?? 0) + amount;
  }
  return totals;
}

double _parseAmount(String value) {
  final cleaned = value.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.-]'), '');
  return double.tryParse(cleaned) ?? 0;
}

List<_CategorySlice> _categorySlices(Map<String, double> totals) {
  const colors = [
    AppColors.coral,
    AppColors.gold,
    AppColors.success,
    Color(0xFF6C63FF),
    Color(0xFF2F80ED),
    Color(0xFF9B51E0),
    Color(0xFFF2994A),
  ];
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (var index = 0; index < entries.length; index++)
      _CategorySlice(
        category: entries[index].key,
        amount: entries[index].value,
        color: colors[index % colors.length],
      ),
  ];
}

String _monthLabel(String key) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final parts = key.split('-');
  if (parts.length != 2) return key;
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return key;
  return '${names[month - 1]} ${parts[0]}';
}

String _money(double value) {
  final hasDecimal = value.truncateToDouble() != value;
  return 'Tk ${value.toStringAsFixed(hasDecimal ? 2 : 0)}';
}
