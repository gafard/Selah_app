import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class Card42ProductDetailsWidget extends StatefulWidget {
  const Card42ProductDetailsWidget({super.key});

  @override
  State<Card42ProductDetailsWidget> createState() => _Card42ProductDetailsWidgetState();
}

class Card42ProductDetailsModel extends FlutterFlowModel<Card42ProductDetailsWidget> {
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

class _Card42ProductDetailsWidgetState extends State<Card42ProductDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Card42 Product Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}