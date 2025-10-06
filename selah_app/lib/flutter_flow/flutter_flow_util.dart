import 'package:flutter/material.dart';

T createModel<T>(BuildContext context, T Function() modelBuilder) {
  return modelBuilder();
}

void safeSetState(VoidCallback callback) {
  callback();
}

Widget wrapWithModel<T>({
  required T model,
  required VoidCallback updateCallback,
  required bool updateOnChange,
  required Widget child,
}) {
  return child;
}