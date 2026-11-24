import 'package:flutter/material.dart';

class GroupsStatus extends StatelessWidget {
  const GroupsStatus({
    super.key,
    required this.loading,
    required this.busy,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final bool busy;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading || busy) const LinearProgressIndicator(),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: loading || busy ? null : onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ],
    );
  }
}
