import 'dart:ui';
import 'package:flutter/material.dart';

class SelahGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  const SelahGlass({
    super.key, 
    required this.child, 
    this.radius = 16, 
    this.padding = const EdgeInsets.all(16)
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const GlassCard({
    super.key, 
    required this.child, 
    this.margin = const EdgeInsets.symmetric(vertical: 12)
  });
  
  @override
  Widget build(BuildContext context) => Container(
    margin: margin, 
    child: SelahGlass(child: child)
  );
}

