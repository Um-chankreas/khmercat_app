import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppService {
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static void showToast(
    String message, {
    bool isError = false,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: isError ? Colors.red.shade600 : Colors.black87,
      textColor: Colors.white,
      fontSize: 14,
    );
  }
}
