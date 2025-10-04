import '/flutter_flow/flutter_flow_util.dart';
import 'payerpage_widget.dart' show PayerpageWidget;
import 'package:flutter/material.dart';

class PayerpageModel extends FlutterFlowModel<PayerpageWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController;

  int carouselCurrentIndex = 1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
