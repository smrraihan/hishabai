import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/receipt_store.dart';
import 'add_receipt_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'receipts_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.user,
    required this.store,
    required this.onLogout,
  });

  final GoogleSignInAccount user;
  final ReceiptStore store;
  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        user: widget.user,
        store: widget.store,
        onAddReceipt: () => setState(() => _index = 1),
        onSeeAll: () => setState(() => _index = 2),
      ),
      AddReceiptScreen(store: widget.store),
      ReceiptsScreen(store: widget.store),
      ProfileScreen(user: widget.user, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.add_a_photo_outlined),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Receipts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
