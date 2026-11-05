import 'package:flutter/material.dart';

import '../../../prototype/demo_data.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_title.dart';
import '../../bills/screens/add_bill_screen.dart';
import '../../bills/screens/sample_bill_screen.dart';
import 'participants_screen.dart';

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
    return AppPage(
      title: group.name,
      children: [
        PageHeader(
          title: group.name,
          subtitle: '${group.participants.length} people, one shared notebook.',
          icon: Icons.groups_outlined,
        ),
        const SectionTitle('The people'),
        if (group.participants.isEmpty)
          const InfoNote(
            text: 'Add participants before recording a bill.',
            icon: Icons.person_add_outlined,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in group.participants)
                Chip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(name == group.self ? '$name (you)' : name),
                ),
            ],
          ),
        const SizedBox(height: 16),
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
          ContentCard(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const SampleBillScreen()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant_outlined),
                    SizedBox(width: 12),
                    Expanded(child: Text('Dinner')),
                    Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'HKD 100.00',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('5 Nov 2026 | Paid by Alex'),
              ],
            ),
          )
        else
          const InfoNote(
            icon: Icons.receipt_long_outlined,
            text: 'No bills yet. Your next shared moment starts here.',
          ),
        const SizedBox(height: 24),
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
