import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/person_row.dart';
import '../../../shared/widgets/section_title.dart';
import '../widgets/bill_summary_card.dart';

class SampleBillScreen extends StatelessWidget {
  const SampleBillScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppPage(
    title: 'Dinner',
    children: [
      BillSummaryCard(
        amount: 'HKD 100.00',
        payer: 'Alex',
        date: 'Friday Dinner | 5 Nov 2026',
        label: 'Synthetic sample bill',
      ),
      SectionTitle('Equal shares - sample'),
      ContentCard(
        child: Column(
          children: [
            PersonRow(
              name: 'Alex (you)',
              subtitle: 'Own share',
              amount: 'HKD 33.34',
            ),
            Divider(),
            PersonRow(
              name: 'Bea',
              subtitle: 'Original bill share owed to Alex',
              amount: 'HKD 33.33',
            ),
            Divider(),
            PersonRow(
              name: 'Chan',
              subtitle: 'Original bill share owed to Alex',
              amount: 'HKD 33.33',
            ),
          ],
        ),
      ),
      SizedBox(height: 20),
      InfoNote(
        text:
            'Synthetic example, not a saved record.\n'
            'Extra cents follow participant order. No payment is verified.',
      ),
    ],
  );
}
