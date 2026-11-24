import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/page_header.dart';
import '../../auth/state/session_scope.dart';
import '../../groups/screens/groups_screen.dart';
import '../../groups/screens/managed_groups_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _initialized = false;
  String? _saved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _name.text = SessionScope.of(context)?.account?.displayName ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context)!;
    final account = session.account!;
    return AppPage(
      title: 'Your account',
      isDemo: false,
      children: [
        PageHeader(
          title: account.displayName == null
              ? 'Make yourself at home.'
              : 'Hello, ${account.displayName}.',
          subtitle: 'Your private SplitSum account.',
          icon: Icons.person_outline,
        ),
        ContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Email'),
              const SizedBox(height: 8),
              Text(account.email),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: TextFormField(
                  controller: _name,
                  enabled: !session.busy,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  onChanged: (_) => setState(() => _saved = null),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a display name.'
                      : null,
                ),
              ),
              const Text(
                'Only you can see this name. It is not a public username '
                'and does not change group participant names.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: session.busy
                    ? null
                    : () async {
                        if (!_form.currentState!.validate()) return;
                        setState(() => _saved = null);
                        await session.updateName(_name.text);
                        if (!mounted || session.account == null) return;
                        if (session.error == null) {
                          setState(() {
                            _name.text = session.account!.displayName ?? '';
                            _saved = 'Display name saved.';
                          });
                        }
                      },
                child: const Text('Save display name'),
              ),
              TextButton(
                onPressed: session.busy
                    ? null
                    : () async {
                        await session.reload();
                        if (!mounted || session.account == null) return;
                        if (session.error == null) {
                          setState(() {
                            _name.text = session.account!.displayName ?? '';
                            _saved = null;
                          });
                        }
                      },
                child: const Text('Reload account'),
              ),
              if (session.busy) const LinearProgressIndicator(),
              if (session.error != null)
                Text(
                  session.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_saved != null) Text(_saved!),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const InfoNote(
          text:
              'Your groups and participants are saved. Bills are not connected '
              'in the app yet. The separate demo uses synthetic data.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: session.busy
              ? null
              : () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManagedGroupsScreen(),
                  ),
                ),
          icon: const Icon(Icons.groups_outlined),
          label: const Text('Your groups'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: session.busy
              ? null
              : () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const GroupsScreen()),
                ),
          child: const Text('Explore demo groups'),
        ),
        TextButton.icon(
          onPressed: session.busy ? null : session.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
