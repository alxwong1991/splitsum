import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/page_header.dart';

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
  Widget build(BuildContext context) => AppPage(
    title: widget.group ? 'Create group' : 'Add participant',
    children: [
      PageHeader(
        title: widget.group ? 'What brings you together?' : 'Who is joining?',
        subtitle: widget.group
            ? 'Give this dinner or trip a name.'
            : 'Just a name. Participants do not need an account.',
        icon: widget.group
            ? Icons.group_add_outlined
            : Icons.person_add_outlined,
      ),
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
      const SizedBox(height: 24),
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
