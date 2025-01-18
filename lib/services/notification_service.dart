import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationService {
  static void showNotification({
    required String message,
    bool isError = false,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showSuccess(String message) {
    showNotification(message: message);
  }

  static void showError(String message) {
    showNotification(message: message, isError: true);
  }
}
