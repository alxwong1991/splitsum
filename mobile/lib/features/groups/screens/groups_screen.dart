import 'package:flutter/material.dart';

import '../../../prototype/demo_data.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_title.dart';
import 'group_screen.dart';
import 'name_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groups = demoGroups();

  Future<void> _open(DemoGroup group) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => GroupScreen(group: group)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NameScreen(group: true)),
    );
    if (!mounted || name == null) return;
    final group = DemoGroup(name, []);
    setState(() => _groups.add(group));
    await _open(group);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Your groups',
    actions: [
      IconButton(
        tooltip: 'Leave demo',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.logout),
      ),
    ],
    children: [
      const PageHeader(
        title: 'Your people.\nYour shared moments.',
        subtitle: 'One owner. Named participants. Simple HKD bills.',
        icon: Icons.people_outline,
      ),
      FilledButton.icon(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Create demo group'),
      ),
      const SectionTitle('Your shared moments'),
      for (final group in _groups) ...[
        ContentCard(
          onTap: () => _open(group),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  group.hasSampleBill
                      ? Icons.restaurant_outlined
                      : Icons.luggage_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('${group.participants.length} participants'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}
