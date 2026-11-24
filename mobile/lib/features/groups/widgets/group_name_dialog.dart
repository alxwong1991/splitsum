import 'package:flutter/material.dart';

Future<String?> showGroupNameDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) {
  final form = GlobalKey<FormState>();
  var name = initialValue;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: form,
        child: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: label),
          onChanged: (value) => name = value,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter a name.' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(context, name.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
