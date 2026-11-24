class Group {
  const Group({
    required this.id,
    required this.name,
    required this.selfParticipantId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? selfParticipantId;
  final DateTime createdAt;

  factory Group.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        (value['id'] as String).isEmpty ||
        value['name'] is! String ||
        !value.containsKey('selfParticipantId') ||
        !(value['selfParticipantId'] == null ||
            value['selfParticipantId'] is String) ||
        value['createdAt'] is! String) {
      throw const FormatException('Invalid group response.');
    }
    final date = DateTime.tryParse(value['createdAt'] as String);
    if (date == null) throw const FormatException('Invalid group date.');
    return Group(
      id: value['id'] as String,
      name: value['name'] as String,
      selfParticipantId: value['selfParticipantId'] as String?,
      createdAt: date,
    );
  }
}

class Participant {
  const Participant({
    required this.id,
    required this.name,
    required this.position,
    required this.archived,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int position;
  final bool archived;
  final DateTime createdAt;

  factory Participant.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        (value['id'] as String).isEmpty ||
        value['name'] is! String ||
        value['position'] is! int ||
        (value['position'] as int) < 0 ||
        value['archived'] is! bool ||
        value['createdAt'] is! String) {
      throw const FormatException('Invalid participant response.');
    }
    final date = DateTime.tryParse(value['createdAt'] as String);
    if (date == null) throw const FormatException('Invalid participant date.');
    return Participant(
      id: value['id'] as String,
      name: value['name'] as String,
      position: value['position'] as int,
      archived: value['archived'] as bool,
      createdAt: date,
    );
  }
}

class GroupDetail {
  const GroupDetail({required this.group, required this.participants});
  final Group group;
  final List<Participant> participants;

  factory GroupDetail.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['participants'] is! List) {
      throw const FormatException('Invalid group details.');
    }
    return GroupDetail(
      group: Group.fromJson(value),
      participants: List.unmodifiable(
        (value['participants'] as List).map(Participant.fromJson),
      ),
    );
  }
}
