import 'package:flutter/material.dart';

extension BuildContextMessage on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
