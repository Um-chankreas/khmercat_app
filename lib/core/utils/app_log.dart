import 'package:flutter/material.dart';

enum LogType { info, success, warning, error }

class AppLog {
  static void print(String message, {LogType type = LogType.info}) {
    final prefix = _prefix(type);
    final formatted = "$prefix $message";
    _defaultPrint(formatted, type: type);
  }

  static void success(String message) => print(message, type: LogType.success);
  static void error(String message) => print(message, type: LogType.error);
  static void warning(String message) => print(message, type: LogType.warning);
  static void info(String message) => print(message, type: LogType.info);
  static void _defaultPrint(String msg, {LogType type = LogType.info}) {
    final colorCode = _colorCode(type);
    const resetCode = '\x1B[0m';
    debugPrint('$colorCode$msg$resetCode');
  }

  static String _colorCode(LogType type) {
    switch (type) {
      case LogType.success:
        return '\x1B[32m'; // Green
      case LogType.warning:
        return '\x1B[33m'; // Yellow
      case LogType.error:
        return '\x1B[31m'; // Red
      case LogType.info:
        return '\x1B[34m'; // Blue
    }
  }

  static String _prefix(LogType type) {
    switch (type) {
      case LogType.success:
        return "[✅ SUCCESS] =>";
      case LogType.warning:
        return "[⚠️ WARNING] =>";
      case LogType.error:
        return "[❌ ERROR] =>";
      case LogType.info:
        return "[ℹ️ INFO] =>";
    }
  }
}
