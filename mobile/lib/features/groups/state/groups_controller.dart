import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/state/session_controller.dart';
import '../data/groups_api.dart';
import '../models/group.dart';

class GroupsController extends ChangeNotifier {
  GroupsController(this.session) : api = GroupsApi(session.api.client);
  final SessionController session;
  final GroupsApi api;

  List<Group>? groups;
  GroupDetail? detail;
  String? error;
  bool loading = false;
  bool busy = false;
  bool needsRefresh = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadGroups() async {
    if (busy || loading) return;
    loading = true;
    error = null;
    _notify();
    try {
      groups = await session.withSession(api.list);
      needsRefresh = false;
    } on ApiException catch (failure) {
      error = failure.message;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> loadDetail(String groupId) async {
    if (busy || loading) return;
    loading = true;
    error = null;
    _notify();
    try {
      detail = await session.withSession((token) => api.detail(token, groupId));
      needsRefresh = false;
    } on ApiException catch (failure) {
      if (failure.status == 404) detail = null;
      error = failure.message;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> createGroup(String name) => _change(
    (token) => api.create(token, name),
    (token) async => groups = await api.list(token),
  );

  Future<void> renameGroup(String groupId, String name) => _change(
    (token) => api.rename(token, groupId, name),
    (token) async => detail = await api.detail(token, groupId),
  );

  Future<void> addParticipant(String groupId, String name) => _change(
    (token) => api.addParticipant(token, groupId, name),
    (token) async => detail = await api.detail(token, groupId),
  );

  Future<void> renameParticipant(
    String groupId,
    String participantId,
    String name,
  ) => _change(
    (token) => api.renameParticipant(token, groupId, participantId, name),
    (token) async => detail = await api.detail(token, groupId),
  );

  Future<void> archiveParticipant(String groupId, String participantId) =>
      _change(
        (token) => api.archiveParticipant(token, groupId, participantId),
        (token) async => detail = await api.detail(token, groupId),
      );

  Future<void> setSelf(String groupId, String? participantId) => _change(
    (token) => api.setSelf(token, groupId, participantId),
    (token) async => detail = await api.detail(token, groupId),
  );

  Future<void> _change(
    Future<Object> Function(String) action,
    Future<void> Function(String) refresh,
  ) async {
    if (busy || loading || needsRefresh) return;
    busy = true;
    error = null;
    _notify();
    try {
      await session.withSession(action);
      try {
        await session.withSession(refresh);
      } on ApiException catch (failure) {
        needsRefresh = true;
        error =
            'Saved, but the latest data could not be loaded. '
            'Refresh before making another change. ${failure.message}';
      }
    } on ApiException catch (failure) {
      needsRefresh = failure.outcomeUnknown;
      error = failure.outcomeUnknown
          ? '${failure.message} The change may have been saved. '
                'It may still be processing. Wait, refresh, and check '
                'before trying again.'
          : failure.message;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
