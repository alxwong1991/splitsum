import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_title.dart';
import '../../auth/state/session_scope.dart';
import '../models/group.dart';
import '../state/groups_controller.dart';
import '../widgets/group_name_dialog.dart';
import '../widgets/groups_status.dart';
import 'managed_group_screen.dart';

class ManagedGroupsScreen extends StatefulWidget {
  const ManagedGroupsScreen({super.key});

  @override
  State<ManagedGroupsScreen> createState() => _ManagedGroupsScreenState();
}

class _ManagedGroupsScreenState extends State<ManagedGroupsScreen> {
  GroupsController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = GroupsController(SessionScope.of(context)!);
      _controller!.loadGroups();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = await showGroupNameDialog(
      context,
      title: 'Create group',
      label: 'Group name',
    );
    if (!mounted || name == null) return;
    await _controller!.createGroup(name);
  }

  Future<void> _open(String groupId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ManagedGroupScreen(controller: _controller!, groupId: groupId),
      ),
    );
    if (mounted) await _controller!.loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final disabled =
            controller.loading ||
            controller.busy ||
            controller.needsRefresh ||
            controller.groups == null;
        return PopScope(
          canPop: !controller.busy && !controller.loading,
          child: AppPage(
            title: 'Your groups',
            isDemo: false,
            actions: [
              IconButton(
                tooltip: 'Refresh groups',
                onPressed: controller.busy || controller.loading
                    ? null
                    : controller.loadGroups,
                icon: const Icon(Icons.refresh),
              ),
            ],
            children: [
              const PageHeader(
                title: 'Your people.\nYour shared moments.',
                subtitle: 'Create a group and add the people sharing with you.',
                icon: Icons.people_outline,
              ),
              FilledButton.icon(
                onPressed: disabled ? null : _create,
                icon: const Icon(Icons.add),
                label: const Text('Create group'),
              ),
              GroupsStatus(
                loading: controller.loading,
                busy: controller.busy,
                error: controller.error,
                onRetry: controller.loadGroups,
              ),
              const SectionTitle('Your groups'),
              if (controller.groups?.isEmpty == true)
                const InfoNote(
                  text: 'No groups yet. Create one to add participants.',
                ),
              for (final group in controller.groups ?? <Group>[]) ...[
                ContentCard(
                  onTap: disabled ? null : () => _open(group.id),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: const Icon(Icons.groups_outlined),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}
