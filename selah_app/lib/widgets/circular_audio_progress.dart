import 'package:flutter/material.dart';

class CircularAudioProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color progressColor;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback? onTap;

  const CircularAudioProgress({
    super.key,
    required this.progress,
    this.size = 60.0,
    this.progressColor = const Color(0xFF007AFF),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.icon = Icons.headphones,
    this.onTap,
  });

  @override
  State<CircularAudioProgress> createState() => _CircularAudioProgressState();
}

class _CircularAudioProgressState extends State<CircularAudioProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle with shadow
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.backgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress circle
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: widget.progress,
                      strokeWidth: 3.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.progressColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  
                  // Icon with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      widget.icon,
                      size: widget.size * 0.4,
                      color: widget.progress > 0 
                          ? widget.progressColor 
                          : Colors.grey[600],
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
