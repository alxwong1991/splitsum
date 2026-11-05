import 'package:flutter/material.dart';

class BillFields extends StatelessWidget {
  const BillFields({
    super.key,
    required this.description,
    required this.total,
    required this.date,
    required this.participants,
    required this.onDateChanged,
    required this.onPayerChanged,
  });

  final TextEditingController description;
  final TextEditingController total;
  final DateTime date;
  final List<String> participants;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String?> onPayerChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: description,
        decoration: const InputDecoration(
          labelText: 'Description',
          hintText: 'Dinner',
          prefixIcon: Icon(Icons.receipt_long_outlined),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Enter a description.'
            : null,
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (context.mounted && selected != null) onDateChanged(selected);
        },
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(MaterialLocalizations.of(context).formatMediumDate(date)),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: total,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Total',
          prefixText: 'HKD ',
          hintText: '100.00',
        ),
        validator: _validateTotal,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Paid by',
          prefixIcon: Icon(Icons.person_outline),
        ),
        items: [
          for (final name in participants)
            DropdownMenuItem(value: name, child: Text(name)),
        ],
        onChanged: onPayerChanged,
        validator: (value) => value == null ? 'Choose one payer.' : null,
      ),
    ],
  );

  static String? _validateTotal(String? value) {
    if (value == null || !RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(value)) {
      return 'Enter a positive HKD total with up to 2 decimals.';
    }
    final parts = value.split('.');
    final cents =
        int.parse(parts[0]) * 100 +
        int.parse(parts.length == 2 ? parts[1].padRight(2, '0') : '0');
    return cents <= 0 || cents > 2147483647
        ? 'Enter between HKD 0.01 and HKD 21,474,836.47.'
        : null;
  }
}
