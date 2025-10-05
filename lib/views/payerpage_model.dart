import '/flutter_flow/flutter_flow_util.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/material.dart';

import 'payerpage_widget.dart' show PayerpageWidget;
import '/components/card42_product_details_widget.dart' show Card42ProductDetailsModel;

class PayerpageModel extends FlutterFlowModel<PayerpageWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for Carousel widget.
  carousel.CarouselController? carouselController;

  int carouselCurrentIndex = 1;

  // Model for card42ProductDetails component.
  late Card42ProductDetailsModel card42ProductDetailsModel;

  @override
  void initState(BuildContext context) {
    card42ProductDetailsModel = createModel(context, () => Card42ProductDetailsModel());
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    card42ProductDetailsModel.dispose();
  }
}