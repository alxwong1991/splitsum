import 'package:flutter/material.dart';

import '../../../prototype/demo_data.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/person_row.dart';
import 'name_screen.dart';

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key, required this.group});
  final DemoGroup group;

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  Future<void> _add() async {
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NameScreen(group: false)),
    );
    if (!mounted || name == null) return;
    if (widget.group.participants.any(
      (existing) => existing.toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use a distinct name in this preview.')),
      );
      return;
    }
    setState(() => widget.group.participants.add(name));
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Participants',
    children: [
      const PageHeader(
        title: 'Everyone at the table.',
        subtitle: 'Names, not accounts. Tap a person to identify yourself.',
        icon: Icons.people_outline,
      ),
      if (widget.group.participants.isEmpty)
        const InfoNote(text: 'No participants yet. Add the first person.')
      else
        ContentCard(
          child: Column(
            children: [
              for (final name in widget.group.participants)
                PersonRow(
                  name: name,
                  subtitle: widget.group.self == name ? 'You' : 'Participant',
                  isSelected: widget.group.self == name,
                  onTap: () => setState(() {
                    widget.group.self = widget.group.self == name ? null : name;
                  }),
                ),
            ],
          ),
        ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _add,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add participant'),
      ),
    ],
  );
}
