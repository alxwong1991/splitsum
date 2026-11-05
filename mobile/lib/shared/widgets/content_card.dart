import 'package:flutter/material.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );
}
