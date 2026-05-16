import 'package:flutter/foundation.dart';

/// Privacy-safe logging utility.
/// 
/// All debug output is gated behind [kDebugMode] to prevent
/// PII leakage to the browser console in Flutter Web release builds.
/// Flutter Web does NOT strip [debugPrint] in release mode, so this
/// wrapper is essential for user privacy.
void safeLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
