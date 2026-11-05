import 'package:flutter/material.dart';

import 'demo_data.dart';

class PrototypePage extends StatelessWidget {
  const PrototypePage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'UI preview only. Synthetic data; no sign-in, payments, '
                      'or database saves. Changes reset when you leave the demo.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _register = false;
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      title: 'SplitSum',
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Good times.\nClear splits.',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Dinner with friends or a weekend away.\n'
          'Keep who paid and who owes easy to follow.',
          textAlign: TextAlign.center,
        ),
        SectionTitle(_register ? 'Create account' : 'Welcome back'),
        const Text('Form layout only. Do not enter real credentials.'),
        const SizedBox(height: 12),
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
            suffixIcon: IconButton(
              tooltip: _hidePassword ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off,
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
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const GroupsScreen())),
          child: const Text('Explore demo'),
        ),
        TextButton(
          onPressed: () => setState(() => _register = !_register),
          child: Text(
            _register
                ? 'Preview sign-in screen'
                : 'Preview create-account screen',
          ),
        ),
      ],
    );
  }
}

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groups = demoGroups();

  Future<void> _create() async {
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NameScreen(group: true)),
    );
    if (!mounted || name == null) return;
    final group = DemoGroup(name, []);
    setState(() => _groups.add(group));
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => GroupScreen(group: group)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
    title: 'Your groups',
    actions: [
      IconButton(
        tooltip: 'Leave demo',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.logout),
      ),
    ],
    children: [
      Text(
        'A little less maths.\nA little more together.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text('One owner. Named participants. Simple HKD bills.'),
      const SectionTitle('Your shared moments'),
      for (final group in _groups)
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              child: Icon(
                group.hasSampleBill ? Icons.restaurant : Icons.people_outline,
              ),
            ),
            title: Text(group.name),
            subtitle: Text('${group.participants.length} participants'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => GroupScreen(group: group),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
        ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Create demo group'),
      ),
    ],
  );
}

class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.group});
  final bool group;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
    title: widget.group ? 'Create group' : 'Add participant',
    children: [
      SectionTitle(
        widget.group ? 'What brings you together?' : 'Who is joining?',
      ),
      Text(
        widget.group
            ? 'Give this dinner or trip a name.'
            : 'Just a name. Participants do not need an account.',
      ),
      const SizedBox(height: 24),
      Form(
        key: _form,
        child: TextFormField(
          controller: _name,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.group ? 'Group name' : 'Participant name',
            hintText: widget.group ? 'Friday Dinner' : 'Alex',
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter a name.' : null,
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.of(context).pop(_name.text.trim());
          }
        },
        child: Text(
          widget.group ? 'Create demo group' : 'Add demo participant',
        ),
      ),
    ],
  );
}

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.group});
  final DemoGroup group;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return PrototypePage(
      title: group.name,
      children: [
        const SectionTitle('The people'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in group.participants)
              Chip(label: Text(name == group.self ? '$name (you)' : name)),
          ],
        ),
        if (group.participants.isEmpty)
          const Text('Add participants before recording a bill.'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ParticipantsScreen(group: group),
              ),
            );
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.people_outline),
          label: const Text('Manage participants'),
        ),
        const SectionTitle('Bills'),
        if (group.hasSampleBill)
          Card(
            child: ListTile(
              title: const Text('Dinner'),
              subtitle: const Text('5 Nov 2026\nPaid by Alex'),
              isThreeLine: true,
              trailing: const Text('HKD 100.00'),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const SampleBillScreen(),
                ),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No bills yet. Your next shared moment starts here.'),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: group.participants.isEmpty
              ? null
              : () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => AddBillScreen(group: group),
                  ),
                ),
          icon: const Icon(Icons.add),
          label: const Text('Preview add bill'),
        ),
      ],
    );
  }
}

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key, required this.group});
  final DemoGroup group;

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  @override
  Widget build(BuildContext context) => PrototypePage(
    title: 'Participants',
    children: [
      const Text('Names, not accounts. Tap a person to identify yourself.'),
      const SizedBox(height: 16),
      if (widget.group.participants.isEmpty)
        const Text('No participants yet. Add the first person.'),
      for (final name in widget.group.participants)
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(name),
            subtitle: Text(widget.group.self == name ? 'You' : 'Participant'),
            trailing: widget.group.self == name
                ? const Icon(Icons.check_circle_outline)
                : null,
            onTap: () => setState(() {
              widget.group.self = widget.group.self == name ? null : name;
            }),
          ),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () async {
          final name = await Navigator.of(context).push<String>(
            MaterialPageRoute<String>(
              builder: (_) => const NameScreen(group: false),
            ),
          );
          if (!context.mounted || name == null) return;
          if (widget.group.participants.any(
            (existing) => existing.toLowerCase() == name.toLowerCase(),
          )) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Use a distinct name in this preview.'),
              ),
            );
            return;
          }
          setState(() => widget.group.participants.add(name));
        },
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add participant'),
      ),
    ],
  );
}

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key, required this.group});
  final DemoGroup group;

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _total = TextEditingController();
  final _selected = <String>{};
  String? _payer;
  String? _selectionError;
  DateTime _date = DateTime(2026, 11, 5);

  @override
  void dispose() {
    _description.dispose();
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
    title: 'Add bill',
    children: [
      const SectionTitle('Who paid for the good times?'),
      Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Dinner',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a description.'
                  : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (mounted && date != null) setState(() => _date = date);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                MaterialLocalizations.of(context).formatMediumDate(_date),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Total',
                prefixText: 'HKD ',
                hintText: '100.00',
              ),
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(value)) {
                  return 'Enter a positive HKD total with up to 2 decimals.';
                }
                final parts = value.split('.');
                final cents =
                    int.parse(parts[0]) * 100 +
                    int.parse(
                      parts.length == 2 ? parts[1].padRight(2, '0') : '0',
                    );
                return cents <= 0 || cents > 2147483647
                    ? 'Enter between HKD 0.01 and HKD 21,474,836.47.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Paid by'),
              items: [
                for (final name in widget.group.participants)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (value) => setState(() => _payer = value),
              validator: (value) => value == null ? 'Choose one payer.' : null,
            ),
          ],
        ),
      ),
      SectionTitle('Split between (${_selected.length} selected)'),
      TextButton(
        onPressed: () => setState(() {
          _selected
            ..clear()
            ..addAll(widget.group.participants);
          _selectionError = null;
        }),
        child: const Text('Select all'),
      ),
      for (final name in widget.group.participants)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(name),
          value: _selected.contains(name),
          onChanged: (value) => setState(() {
            value == true ? _selected.add(name) : _selected.remove(name);
            _selectionError = null;
          }),
        ),
      if (_selectionError != null)
        Text(
          _selectionError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      const SizedBox(height: 12),
      const Text(
        'One payer, equal shares. The payer can be excluded.\n'
        'Exact shares will be calculated by the backend in Stage 1.',
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () {
          final valid = _form.currentState!.validate();
          setState(() {
            _selectionError = _selected.isEmpty
                ? 'Select at least one person.'
                : null;
          });
          if (!valid || _selected.isEmpty) return;
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => DraftScreen(
                description: _description.text.trim(),
                total: _total.text,
                payer: _payer!,
                participants: widget.group.participants
                    .where(_selected.contains)
                    .toList(),
                date: _date,
              ),
            ),
          );
        },
        child: const Text('Preview bill (not saved)'),
      ),
    ],
  );
}

class DraftScreen extends StatelessWidget {
  const DraftScreen({
    super.key,
    required this.description,
    required this.total,
    required this.payer,
    required this.participants,
    required this.date,
  });

  final String description;
  final String total;
  final String payer;
  final List<String> participants;
  final DateTime date;

  @override
  Widget build(BuildContext context) => PrototypePage(
    title: 'Bill preview',
    children: [
      SectionTitle(description),
      Text(MaterialLocalizations.of(context).formatMediumDate(date)),
      const SizedBox(height: 16),
      Text('HKD $total', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      Text('Paid by $payer'),
      const SectionTitle('Split equally between'),
      for (final name in participants) ListTile(title: Text(name)),
      if (!participants.contains(payer))
        const Text('Payer is not included in the split.'),
      const SizedBox(height: 20),
      const Text(
        'Layout preview only. No shares calculated and no bill saved.\n'
        'Use Back to continue editing.',
      ),
    ],
  );
}

class SampleBillScreen extends StatelessWidget {
  const SampleBillScreen({super.key});

  @override
  Widget build(BuildContext context) => PrototypePage(
    title: 'Dinner',
    children: [
      const Text('Friday Dinner | 5 Nov 2026'),
      const SizedBox(height: 24),
      Text('HKD 100.00', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      const Text('Paid by Alex'),
      const SectionTitle('Equal shares - sample'),
      const Card(
        child: Column(
          children: [
            ListTile(
              title: Text('Alex (you)'),
              subtitle: Text('Own share'),
              trailing: Text('HKD 33.34'),
            ),
            ListTile(
              title: Text('Bea'),
              subtitle: Text('Original bill share owed to Alex'),
              trailing: Text('HKD 33.33'),
            ),
            ListTile(
              title: Text('Chan'),
              subtitle: Text('Original bill share owed to Alex'),
              trailing: Text('HKD 33.33'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Synthetic example, not a saved record.\n'
        'Extra cents follow participant order. No payment is verified.',
      ),
    ],
  );
}
