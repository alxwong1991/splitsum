import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../groups/screens/groups_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _register = false;
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'SplitSum',
    children: [
      const PageHeader(
        title: 'Good times.\nClear splits.',
        subtitle:
            'Dinner with friends or a weekend away.\n'
            'Less maths. More together.',
        icon: Icons.receipt_long_outlined,
      ),
      ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _register ? 'Create account' : 'Welcome back',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Form layout only. Do not enter real credentials.'),
            const SizedBox(height: 24),
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'alex@example.invalid',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (_register) ...[
              const SizedBox(height: 16),
              const TextField(
                readOnly: true,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm password'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GroupsScreen()),
              ),
              child: const Text('Explore demo'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _register = !_register),
              child: Text(
                _register
                    ? 'Preview sign-in screen'
                    : 'Preview create-account screen',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
