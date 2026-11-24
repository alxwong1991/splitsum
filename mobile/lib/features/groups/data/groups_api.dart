import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/group.dart';

class GroupsApi {
  GroupsApi(this.client);
  final ApiClient client;

  Future<Object?> _request(
    String method,
    String path,
    String token, {
    Map<String, Object?>? body,
  }) async {
    try {
      return await client.request(method, path, token: token, body: body);
    } on ApiException catch (failure) {
      if (failure.status == 404) {
        throw const ApiException(
          'Group or participant not found.',
          status: 404,
        );
      }
      if (failure.status == 409) {
        throw const ApiException(
          'This participant is archived. Refresh to see the latest details.',
          status: 409,
        );
      }
      rethrow;
    }
  }

  T _decode<T>(T Function() decode, {bool outcomeUnknown = false}) {
    try {
      return decode();
    } on FormatException {
      throw ApiException(
        'The backend returned invalid group data.',
        outcomeUnknown: outcomeUnknown,
      );
    }
  }

  Future<List<Group>> list(String token) async {
    final value = await _request('GET', '/groups', token);
    return _decode(() {
      if (value is! List) throw const FormatException('Invalid groups.');
      return List.unmodifiable(value.map(Group.fromJson));
    });
  }

  Future<GroupDetail> detail(String token, String groupId) async {
    final value = await _request('GET', '/groups/$groupId', token);
    return _decode(() => GroupDetail.fromJson(value));
  }

  Future<Group> create(String token, String name) async {
    final value = await _request(
      'POST',
      '/groups',
      token,
      body: {'name': name},
    );
    return _decode(() => Group.fromJson(value), outcomeUnknown: true);
  }

  Future<Group> rename(String token, String groupId, String name) async {
    final value = await _request(
      'PATCH',
      '/groups/$groupId',
      token,
      body: {'name': name},
    );
    return _decode(() => Group.fromJson(value), outcomeUnknown: true);
  }

  Future<Participant> addParticipant(
    String token,
    String groupId,
    String name,
  ) async {
    final value = await _request(
      'POST',
      '/groups/$groupId/participants',
      token,
      body: {'name': name},
    );
    return _decode(() => Participant.fromJson(value), outcomeUnknown: true);
  }

  Future<Participant> renameParticipant(
    String token,
    String groupId,
    String participantId,
    String name,
  ) async {
    final value = await _request(
      'PATCH',
      '/groups/$groupId/participants/$participantId',
      token,
      body: {'name': name},
    );
    return _decode(() => Participant.fromJson(value), outcomeUnknown: true);
  }

  Future<Participant> archiveParticipant(
    String token,
    String groupId,
    String participantId,
  ) async {
    final value = await _request(
      'PATCH',
      '/groups/$groupId/participants/$participantId/archive',
      token,
    );
    return _decode(() => Participant.fromJson(value), outcomeUnknown: true);
  }

  Future<Group> setSelf(
    String token,
    String groupId,
    String? participantId,
  ) async {
    final value = await _request(
      'PUT',
      '/groups/$groupId/self',
      token,
      body: {'participantId': participantId},
    );
    return _decode(() => Group.fromJson(value), outcomeUnknown: true);
  }
}
