import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../account/screens/account_screen.dart';
import '../state/session_controller.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.session});
  final SessionController session;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.session.account != null) {
      widget.session.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (session.restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session.restoreFailed) {
      return AppPage(
        title: 'Session unavailable',
        isDemo: false,
        children: [
          Text(session.error ?? 'Could not restore your session.'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: session.busy ? null : session.restore,
            child: const Text('Retry session'),
          ),
          TextButton(
            onPressed: session.busy ? null : session.signOut,
            child: const Text('Clear session and sign in'),
          ),
        ],
      );
    }
    return session.account == null
        ? const WelcomeScreen()
        : const AccountScreen();
  }
}
