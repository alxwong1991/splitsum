import 'package:flutter/material.dart';

import '../../../prototype/demo_data.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_title.dart';
import '../widgets/bill_fields.dart';
import 'draft_screen.dart';

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

  void _preview() {
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
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Add bill',
    children: [
      PageHeader(
        title: 'One bill.\nA fair share.',
        subtitle: widget.group.name,
        icon: Icons.receipt_long_outlined,
      ),
      Form(
        key: _form,
        child: BillFields(
          description: _description,
          total: _total,
          date: _date,
          participants: widget.group.participants,
          onDateChanged: (value) => setState(() => _date = value),
          onPayerChanged: (value) => setState(() => _payer = value),
        ),
      ),
      SectionTitle('Split between (${_selected.length} selected)'),
      ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
          ],
        ),
      ),
      if (_selectionError != null) ...[
        const SizedBox(height: 12),
        Text(
          _selectionError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: 20),
      const InfoNote(
        text:
            'One payer, equal shares. The payer can be excluded.\n'
            'Exact shares will be calculated by the backend in Stage 1.',
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _preview,
        child: const Text('Preview bill (not saved)'),
      ),
    ],
  );
}
