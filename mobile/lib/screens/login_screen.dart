import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onContinue, this.error});

  final VoidCallback onContinue;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/hishabAI_logo.png',
                      width: 112,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'hishabAI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Receipt out of your wallet.\nInto hishabAI.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Capture receipts, review details, and let hishabAI organize your spending.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 42),
                  FilledButton.icon(
                    onPressed: onContinue,
                    icon: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    label: const Text('Continue with Google'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.coral),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Your receipts stay private and are only shown inside '
                    'your account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
