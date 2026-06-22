import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/receipt_store.dart';
import 'theme/app_theme.dart';

class HishabAiApp extends StatefulWidget {
  const HishabAiApp({super.key});

  @override
  State<HishabAiApp> createState() => _HishabAiAppState();
}

class _HishabAiAppState extends State<HishabAiApp> {
  final _auth = AuthService();
  bool _loading = true;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await _auth.restoreSession();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _loginError = null;
    });
    try {
      await _auth.signIn();
    } catch (error) {
      _loginError = error.toString().replaceFirst('Bad state: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hishabAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _auth.currentUser != null
            ? MainShell(
                key: const ValueKey('main'),
                user: _auth.currentUser!,
                store: ReceiptStore(ApiService(_auth))..refresh(),
                onLogout: _logout,
              )
            : LoginScreen(
                key: const ValueKey('login'),
                error: _loginError,
                onContinue: _login,
              ),
      ),
    );
  }
}
