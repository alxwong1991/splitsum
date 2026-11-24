class ApiException implements Exception {
  const ApiException(this.message, {this.status, this.outcomeUnknown = false});
  final String message;
  final int? status;
  final bool outcomeUnknown;
}
