import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/receipt.dart';
import '../services/receipt_store.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final firstName = user.displayName?.split(' ').first ?? 'there';
    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => RefreshIndicator(
          onRefresh: store.refresh,
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
                    backgroundImage: user.photoUrl == null
                        ? null
                        : NetworkImage(user.photoUrl!),
                    child: user.photoUrl == null
                        ? Text(_initials(user.displayName))
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
                      '${store.receipts.length}',
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
                      onTap: onAddReceipt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'My receipts',
                      color: AppColors.paleGold,
                      onTap: onSeeAll,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'Recent transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(onPressed: onSeeAll, child: const Text('See all')),
                ],
              ),
              if (store.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (!store.loading && store.receipts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Your saved receipts will appear here.'),
                  ),
                ),
              ...store.receipts
                  .take(3)
                  .map((receipt) => _TransactionTile(receipt: receipt)),
            ],
          ),
        ),
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
  const _TransactionTile({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
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
