import 'dart:async';
import 'dart:io';

/// Lightweight internet check — no extra packages needed.
/// Used by features that require network access (e.g. Flag Quiz images).
class ConnectivityService {
  ConnectivityService._();

  /// Returns true when a DNS lookup for the flag image host succeeds.
  /// Fast-fails after 4 seconds so the UI never hangs.
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('flagsapi.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
