import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user, required this.onLogout});

  final GoogleSignInAccount user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.paleGold,
                  backgroundImage: user.photoUrl == null
                      ? null
                      : NetworkImage(user.photoUrl!),
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, color: AppColors.ink)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Google user',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Private account data'),
            subtitle: Text('Only your receipts are returned to this app.'),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.coral,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    ),
  );
}
