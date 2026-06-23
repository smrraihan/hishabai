import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../services/receipt_store.dart';
import '../theme/app_theme.dart';

class ReceiptDetailScreen extends StatefulWidget {
  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
    required this.store,
  });

  final Receipt receipt;
  final ReceiptStore store;

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  late Future<ReceiptDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.store.api.detail(widget.receipt.receiptId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt detail')),
      body: SafeArea(
        child: FutureBuilder<ReceiptDetail>(
          future: _detail,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString().replaceFirst(
                  'Bad state: ',
                  '',
                ),
                onRetry: () => setState(
                  () => _detail = widget.store.api.detail(
                    widget.receipt.receiptId,
                  ),
                ),
              );
            }

            final detail = snapshot.data!;
            final receipt = detail.receipt;
            final imageBytes = base64Decode(detail.imageBase64);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ReceiptImage(imageBytes: imageBytes),
                const SizedBox(height: 22),
                Text(
                  receipt.merchantName.isEmpty
                      ? 'Unknown merchant'
                      : receipt.merchantName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${receipt.category} · ${receipt.transactionDate}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Amount', value: receipt.amount),
                        _DetailRow(
                          label: 'Transaction type',
                          value: receipt.transactionType,
                        ),
                        _DetailRow(
                          label: 'Merchant',
                          value: receipt.merchantName,
                        ),
                        _DetailRow(
                          label: 'Transaction date',
                          value: receipt.transactionDate,
                        ),
                        _DetailRow(
                          label: 'Transaction time',
                          value: receipt.transactionTime,
                        ),
                        _DetailRow(
                          label: 'Transaction ID',
                          value: receipt.transactionId,
                        ),
                        _DetailRow(label: 'Category', value: receipt.category),
                        _DetailRow(
                          label: 'Receipt ID',
                          value: receipt.receiptId,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReceiptImage extends StatelessWidget {
  const _ReceiptImage({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) => Container(
    height: 360,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFD8D5CD), width: 1.5),
    ),
    child: InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 128,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    ),
  );
}
