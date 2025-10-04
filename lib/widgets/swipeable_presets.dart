import 'package:flutter/material.dart';
import 'package:essai/models/plan_preset.dart';
import 'package:essai/widgets/plan_card.dart';

class SwipeablePresets extends StatefulWidget {
  final List<PlanPreset> items;
  final void Function(PlanPreset preset, bool accepted)? onSwipe; // true=right, false=left

  const SwipeablePresets({
    super.key,
    required this.items,
    this.onSwipe,
  });

  @override
  State<SwipeablePresets> createState() => _SwipeablePresetsState();
}

class _SwipeablePresetsState extends State<SwipeablePresets> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _offset = Offset.zero;
  double _angle = 0.0; // rotation (radians)
  int _topIndex = 0;

  static const _swipeThreshold = 140.0;
  static const _maxAngle = 0.20; // ~11.5°

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  void _animateBack() {
    _controller.forward(from: 0).then((_) => _controller.reset());
    setState(() {
      _offset = Offset.zero;
      _angle = 0;
    });
  }

  void _completeSwipe(bool right) {
    final swiped = widget.items[_topIndex];
    widget.onSwipe?.call(swiped, right);
    setState(() {
      _topIndex = (_topIndex + 1).clamp(0, widget.items.length);
      _offset = Offset.zero;
      _angle = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_topIndex >= widget.items.length) {
      return Center(
        child: Text(
          "Plus de presets",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final cards = <Widget>[];
    final last = widget.items.length - 1;

    for (int i = _topIndex; i < widget.items.length; i++) {
      final isTop = i == _topIndex;
      final depth = i - _topIndex;

      final base = Transform.translate(
        offset: isTop ? _offset : Offset(0, depth * 14),
        child: Transform.rotate(
          angle: isTop ? _angle : 0,
          child: Opacity(
            opacity: isTop ? 1 : .9 - depth * .1,
            child: PresetCard(preset: widget.items[i]),
          ),
        ),
      );

      final padded = Positioned.fill(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: isTop ? 16 : 16 + depth * 8),
          child: isTop
              ? GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _offset += d.delta;
                      _angle = (_offset.dx / 300).clamp(-_maxAngle, _maxAngle);
                    });
                  },
                  onPanEnd: (_) {
                    if (_offset.dx.abs() > _swipeThreshold) {
                      final right = _offset.dx > 0;
                      // Animation de sortie
                      setState(() {
                        _offset += Offset(right ? 600 : -600, 0);
                      });
                      Future.delayed(const Duration(milliseconds: 160), () => _completeSwipe(right));
                    } else {
                      _animateBack();
                    }
                  },
                  child: base,
                )
              : base,
        ),
      );

      cards.add(padded);
    }

    // On dessine du bas vers le haut
    return Stack(children: cards.reversed.toList());
  }
}
