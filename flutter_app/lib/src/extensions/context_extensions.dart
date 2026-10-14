import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  void showSnackBar(String mensaje) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
