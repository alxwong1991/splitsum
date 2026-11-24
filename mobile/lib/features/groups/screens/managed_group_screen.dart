import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/info_note.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_title.dart';
import '../models/group.dart';
import '../state/groups_controller.dart';
import '../widgets/group_name_dialog.dart';
import '../widgets/groups_status.dart';

class ManagedGroupScreen extends StatefulWidget {
  const ManagedGroupScreen({
    super.key,
    required this.controller,
    required this.groupId,
  });

  final GroupsController controller;
  final String groupId;

  @override
  State<ManagedGroupScreen> createState() => _ManagedGroupScreenState();
}

class _ManagedGroupScreenState extends State<ManagedGroupScreen> {
  GroupsController get controller => widget.controller;
  bool _requestedDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestedDetails = true;
        controller.loadDetail(widget.groupId);
      }
    });
  }

  Future<void> _renameGroup(Group group) async {
    final name = await showGroupNameDialog(
      context,
      title: 'Rename group',
      label: 'Group name',
      initialValue: group.name,
    );
    if (!mounted || name == null || name == group.name) return;
    await controller.renameGroup(widget.groupId, name);
  }

  Future<void> _addParticipant() async {
    final name = await showGroupNameDialog(
      context,
      title: 'Add participant',
      label: 'Participant name',
    );
    if (!mounted || name == null) return;
    await controller.addParticipant(widget.groupId, name);
  }

  Future<void> _renameParticipant(Participant person) async {
    final name = await showGroupNameDialog(
      context,
      title: 'Rename participant',
      label: 'Participant name',
      initialValue: person.name,
    );
    if (!mounted || name == null || name == person.name) return;
    await controller.renameParticipant(widget.groupId, person.id, name);
  }

  Future<void> _archive(Participant person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive participant?'),
        content: Text(
          '${person.name} will no longer be selectable for new bills. '
          'Their history remains. If this person represents you, that selection '
          'will be cleared. This cannot be undone yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await controller.archiveParticipant(widget.groupId, person.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final detail = controller.detail;
        final current = _requestedDetails && detail?.group.id == widget.groupId
            ? detail
            : null;
        final disabled =
            controller.busy || controller.loading || controller.needsRefresh;
        final active =
            current?.participants.where((p) => !p.archived).toList() ?? [];
        final archived =
            current?.participants.where((p) => p.archived).toList() ?? [];
        return PopScope(
          canPop: !controller.busy && !controller.loading,
          child: AppPage(
            title: current?.group.name ?? 'Group',
            isDemo: false,
            actions: [
              IconButton(
                tooltip: 'Refresh group',
                onPressed: controller.busy || controller.loading
                    ? null
                    : () => controller.loadDetail(widget.groupId),
                icon: const Icon(Icons.refresh),
              ),
            ],
            children: [
              GroupsStatus(
                loading: controller.loading,
                busy: controller.busy,
                error: controller.error,
                onRetry: () => controller.loadDetail(widget.groupId),
              ),
              if (current != null) ...[
                PageHeader(
                  title: current.group.name,
                  subtitle: '${active.length} active participants.',
                  icon: Icons.groups_outlined,
                ),
                OutlinedButton.icon(
                  onPressed: disabled
                      ? null
                      : () => _renameGroup(current.group),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Rename group'),
                ),
                const SectionTitle('Participants'),
                const Text(
                  'Participants are names, not accounts. Select who represents you.',
                ),
                const SizedBox(height: 12),
                if (active.isEmpty)
                  const InfoNote(text: 'No active participants yet.')
                else
                  ContentCard(
                    child: Column(
                      children: [
                        for (final person in active)
                          _participantRow(person, current.group, disabled),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: disabled ? null : _addParticipant,
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add participant'),
                ),
                if (archived.isNotEmpty) ...[
                  const SectionTitle('Archived participants'),
                  ContentCard(
                    child: Column(
                      children: [
                        for (final person in archived)
                          ListTile(
                            leading: const Icon(Icons.archive_outlined),
                            title: Text(person.name),
                            subtitle: const Text('Archived'),
                          ),
                      ],
                    ),
                  ),
                ],
                const SectionTitle('Bills'),
                const InfoNote(
                  text: 'Bill entry and history are not connected in the app yet.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _participantRow(Participant person, Group group, bool disabled) {
    final isSelf = person.id == group.selfParticipantId;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.person_outline),
      ),
      title: Text(person.name),
      subtitle: Text(
        isSelf
            ? 'You - participant ${person.position + 1}'
            : 'Participant ${person.position + 1}',
      ),
      onTap: disabled
          ? null
          : () => controller.setSelf(widget.groupId, isSelf ? null : person.id),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelf)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          PopupMenuButton<String>(
            tooltip: 'Options for ${person.name}',
            enabled: !disabled,
            onSelected: (value) {
              if (value == 'rename') {
                _renameParticipant(person);
              } else if (value == 'archive') {
                _archive(person);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
          ),
        ],
      ),
    );
  }
}
