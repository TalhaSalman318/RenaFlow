import 'dart:developer' as developer;

export 'dart:io' show SocketException;

void debugApiLog(String message) {
  developer.log(message, name: 'RenalFlow.ApiService');
}
