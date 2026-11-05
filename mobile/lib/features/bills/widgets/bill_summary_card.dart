import 'package:flutter/material.dart';

class BillSummaryCard extends StatelessWidget {
  const BillSummaryCard({
    super.key,
    required this.amount,
    required this.payer,
    required this.date,
    required this.label,
  });

  final String amount;
  final String payer;
  final String date;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onPrimary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 12),
            Text(
              amount,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Text('Paid by $payer'),
            const SizedBox(height: 4),
            Text(date),
          ],
        ),
      ),
    );
  }
}
