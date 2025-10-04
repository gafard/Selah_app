import 'package:flutter/material.dart';

class FlutterFlowWidgets {
  static Widget wrapWithModel<T>({
    required T model,
    required Widget child,
    required VoidCallback updateCallback,
    required bool updateOnChange,
  }) {
    return child;
  }
}
