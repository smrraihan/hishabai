import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../services/receipt_store.dart';
import '../theme/app_theme.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key, required this.store});

  final ReceiptStore store;

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final receipts = widget.store.receipts.where((receipt) {
            final haystack = '${receipt.merchantName} ${receipt.transactionId}'
                .toLowerCase();
            return haystack.contains(_query.toLowerCase());
          }).toList();
          return RefreshIndicator(
            onRefresh: widget.store.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'My receipts',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Only receipts linked to your Google account.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search merchant or transaction ID',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 18),
                if (widget.store.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (widget.store.error != null)
                  _Message(
                    message: widget.store.error!,
                    retry: widget.store.refresh,
                  ),
                if (!widget.store.loading &&
                    widget.store.error == null &&
                    receipts.isEmpty)
                  const _Message(
                    message:
                        'No receipts yet. Add your first receipt from the Add tab.',
                  ),
                ...receipts.map((receipt) => _ReceiptCard(receipt: receipt)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.paleGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.merchantName.isEmpty
                      ? 'Unknown merchant'
                      : receipt.merchantName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('${receipt.category} · ${receipt.transactionDate}'),
                const SizedBox(height: 5),
                Text(
                  receipt.receiptId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            receipt.amount,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
