import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_tokens.dart';

/// Scaffold avec gradient Calm et SafeArea
class CalmGradientScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;
  
  const CalmGradientScaffold({
    super.key, 
    required this.child, 
    this.appBar,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTokens.backgroundGradient,
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// Carte avec effet verre (glass morphism)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  
  const GlassCard({
    super.key, 
    required this.child, 
    this.padding = const EdgeInsets.all(AppTokens.gap20),
    this.radius = AppTokens.r20,
    this.backgroundColor,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTokens.glassBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTokens.glassBorder, width: 1),
        boxShadow: shadows ?? [AppTokens.shadowLight],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      );
    }
    
    return card;
  }
}

/// Barre de progression animée
class CalmProgressBar extends StatelessWidget {
  final double progress; // 0.0 à 1.0
  final String? label;
  final Color? color;
  
  const CalmProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTokens.gap8),
        ],
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: AnimatedContainer(
            duration: AppTokens.normal,
            curve: AppTokens.curve,
            width: MediaQuery.of(context).size.width * progress,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color ?? AppTokens.indigo,
                  (color ?? AppTokens.indigo).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicateur de statut avec animation
class StatusIndicator extends StatefulWidget {
  final bool isActive;
  final String label;
  final IconData icon;
  final Color? color;
  
  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTokens.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppTokens.spring,
    ));
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward().then((_) => _controller.reverse());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.gap12,
              vertical: AppTokens.gap8,
            ),
            decoration: BoxDecoration(
              color: widget.isActive 
                  ? (widget.color ?? AppTokens.success).withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(
                color: widget.isActive 
                    ? (widget.color ?? AppTokens.success).withOpacity(0.3)
                    : AppTokens.glassBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isActive 
                      ? (widget.color ?? AppTokens.success)
                      : Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: AppTokens.gap8),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: widget.isActive 
                        ? (widget.color ?? AppTokens.success)
                        : Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bouton avec effet shimmer subtil
class CalmButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? gradient;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  
  const CalmButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<CalmButton> createState() => _CalmButtonState();
}

class _CalmButtonState extends State<CalmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: AppTokens.curve,
    ));
    
    // Déclencher l'animation shimmer à l'apparition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shimmerController.forward();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _shimmerAnimation.value,
          child: Container(
            width: widget.width,
            height: 48,
            decoration: BoxDecoration(
              gradient: widget.gradient as Gradient? ?? const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: [
                BoxShadow(
                  color: (widget.gradient?.first ?? AppTokens.indigo).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: AppTokens.gap8),
                            ],
                            Text(
                              widget.text,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

