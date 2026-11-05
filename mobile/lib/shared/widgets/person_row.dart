import 'package:flutter/material.dart';

class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.name,
    this.subtitle,
    this.amount,
    this.isSelected = false,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final String? amount;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      child: const Icon(Icons.person_outline),
    );
    return Semantics(
      selected: onTap == null ? null : isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                    if (amount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        amount!,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
