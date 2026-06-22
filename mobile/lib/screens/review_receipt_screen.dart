import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../services/receipt_store.dart';
import '../theme/app_theme.dart';

class ReviewReceiptScreen extends StatefulWidget {
  const ReviewReceiptScreen({
    super.key,
    required this.receipt,
    required this.imageBytes,
    required this.mimeType,
    required this.store,
  });

  final Receipt receipt;
  final Uint8List imageBytes;
  final String mimeType;
  final ReceiptStore store;

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _type;
  late final TextEditingController _merchant;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _transactionId;
  late String _category;
  bool _saving = false;
  String? _error;

  static const categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
    'Education',
    'Salary',
    'Transfer',
    'Investment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.receipt.amount);
    _type = TextEditingController(text: widget.receipt.transactionType);
    _merchant = TextEditingController(text: widget.receipt.merchantName);
    _date = TextEditingController(text: widget.receipt.transactionDate);
    _time = TextEditingController(text: widget.receipt.transactionTime);
    _transactionId = TextEditingController(text: widget.receipt.transactionId);
    _category = categories.contains(widget.receipt.category)
        ? widget.receipt.category
        : 'Other';
  }

  @override
  void dispose() {
    _amount.dispose();
    _type.dispose();
    _merchant.dispose();
    _date.dispose();
    _time.dispose();
    _transactionId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final corrected = widget.receipt.copyWith(
      amount: _amount.text.trim(),
      transactionType: _type.text.trim(),
      merchantName: _merchant.text.trim(),
      transactionDate: _date.text.trim(),
      transactionTime: _time.text.trim(),
      transactionId: _transactionId.text.trim(),
      category: _category,
    );
    try {
      await widget.store.api.save(
        receipt: corrected,
        imageBytes: widget.imageBytes,
        mimeType: widget.mimeType,
      );
      await widget.store.refresh();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFE1F4EA),
                child: Icon(Icons.check, size: 36, color: AppColors.success),
              ),
              const SizedBox(height: 18),
              Text(
                'Receipt saved',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'The private receipt, JSON, and spreadsheet row were saved.',
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review transaction')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              widget.imageBytes,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paleGold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.ink),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI extracted these details. Review them before saving.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _field(_amount, 'Amount'),
          _field(_type, 'Transaction type'),
          _field(_merchant, 'Merchant'),
          _field(_date, 'Transaction date'),
          _field(_time, 'Transaction time'),
          _field(_transactionId, 'Transaction ID'),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: categories
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.coral)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save receipt'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
