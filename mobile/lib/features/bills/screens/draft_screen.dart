import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/person_row.dart';
import '../../../shared/widgets/section_title.dart';
import '../widgets/bill_summary_card.dart';

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
  Widget build(BuildContext context) => AppPage(
    title: 'Bill preview',
    children: [
      BillSummaryCard(
        amount: 'HKD $total',
        payer: payer,
        date: MaterialLocalizations.of(context).formatMediumDate(date),
        label: description,
      ),
      const SectionTitle('Split equally between'),
      ContentCard(
        child: Column(
          children: [
            for (final name in participants)
              PersonRow(
                name: name,
                subtitle: name == payer ? 'Payer included' : 'Participant',
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (!participants.contains(payer)) ...[
        const InfoNote(text: 'Payer is not included in the split.'),
        const SizedBox(height: 12),
      ],
      const InfoNote(
        text:
            'Layout preview only. No shares calculated and no bill saved.\n'
            'Use Back to continue editing.',
      ),
    ],
  );
}
