class Account {
  const Account({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;

  factory Account.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        value['email'] is! String ||
        !(value['displayName'] == null || value['displayName'] is String) ||
        value['createdAt'] is! String) {
      throw const FormatException('Invalid account response.');
    }
    final date = DateTime.tryParse(value['createdAt'] as String);
    if (date == null) throw const FormatException('Invalid account date.');
    return Account(
      id: value['id'] as String,
      email: value['email'] as String,
      displayName: value['displayName'] as String?,
      createdAt: date,
    );
  }
}
