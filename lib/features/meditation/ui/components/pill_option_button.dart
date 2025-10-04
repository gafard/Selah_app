import 'package:flutter/material.dart';
import '../../../../theme/design_tokens.dart';

/// Bouton pill avec états normal/sélectionné et animations
class PillOptionButton extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;
  final bool enabled;

  const PillOptionButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.selectedColor,
    this.enabled = true,
  });

  @override
  State<PillOptionButton> createState() => _PillOptionButtonState();
}

class _PillOptionButtonState extends State<PillOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.animationCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _animationController.forward() : null,
      onTapUp: widget.enabled ? (_) => _animationController.reverse() : null,
      onTapCancel: widget.enabled ? () => _animationController.reverse() : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: DesignTokens.pillHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.pillPadding,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: widget.isSelected 
                    ? DesignTokens.white22 
                    : DesignTokens.white14,
                borderRadius: BorderRadius.circular(DesignTokens.pillRadius),
                border: widget.isSelected 
                    ? Border.all(color: DesignTokens.white55, width: 1)
                    : null,
                boxShadow: widget.isSelected 
                    ? [DesignTokens.softShadow]
                    : null,
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.enabled 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.text,
                      style: DesignTokens.button.copyWith(
                        color: widget.enabled 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
