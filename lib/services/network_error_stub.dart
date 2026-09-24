import 'package:flutter/foundation.dart';

class SocketException implements Exception {
  const SocketException(this.message);

  final String message;

  @override
  String toString() => message;
}

void debugApiLog(String message) {
  debugPrint('[RenalFlow.ApiService] $message');
}
