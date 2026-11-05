import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../groups/screens/groups_screen.dart';
import '../state/session_scope.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _register = false;
  bool _hidePassword = true;
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final busy = session?.busy ?? false;
    return AppPage(
      title: 'SplitSum',
      isDemo: false,
      children: [
        const PageHeader(
          title: 'Good times.\nClear splits.',
          subtitle:
              'Dinner with friends or a weekend away.\n'
              'Less maths. More together.',
          icon: Icons.receipt_long_outlined,
        ),
        ContentCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _register ? 'Create account' : 'Welcome back',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Sign in to manage your private account.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'alex@example.invalid',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (value) =>
                      value == null ||
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value.trim())
                      ? 'Enter a valid email.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: !busy,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: _hidePassword,
                  validator: (value) =>
                      value == null || value.length < 15 || value.length > 128
                      ? 'Use 15-128 characters.'
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: busy
                          ? null
                          : () =>
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
                  TextFormField(
                    controller: _confirmation,
                    enabled: !busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (value) => value != _password.text
                        ? 'Passwords do not match.'
                        : null,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy || session == null
                      ? null
                      : () async {
                          if (!_form.currentState!.validate()) return;
                          await session.authenticate(
                            register: _register,
                            email: _email.text,
                            password: _password.text,
                          );
                        },
                  child: Text(_register ? 'Create account' : 'Sign in'),
                ),
                if (busy) const LinearProgressIndicator(),
                if (session?.error != null)
                  Text(
                    session!.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          _register = !_register;
                          _confirmation.clear();
                          _form.currentState?.reset();
                        }),
                  child: Text(
                    _register
                        ? 'Already have an account? Sign in'
                        : 'New here? Create account',
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const GroupsScreen(),
                          ),
                        ),
                  child: const Text('Explore demo'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
