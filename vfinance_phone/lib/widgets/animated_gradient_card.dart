import 'package:flutter/material.dart';

/// A high-performance animated gradient card with a "liquid light" effect.
/// 
/// This widget animates the gradient's alignment to create a smooth,
/// premium breathing effect without impacting APK size (no assets).
/// 
/// Uses [RepaintBoundary] to isolate repaints for battery efficiency.
class AnimatedGradientCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final List<Color>? colors;
  
  const AnimatedGradientCard({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(24),
    this.colors,
  });

  @override
  State<AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _beginAlignment;
  late Animation<Alignment> _endAlignment;

  // Default premium dark mode gradient colors
  static const List<Color> _defaultColors = [
    Color(0xFF4A00E0), // Deep Purple
    Color(0xFF8E2DE2), // Violet
    Color(0xFF00D4FF), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true); // Smooth back-and-forth breathing

    // Animate begin alignment: topLeft -> topRight -> topLeft
    _beginAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Animate end alignment: bottomRight -> bottomLeft -> bottomRight
    _endAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? _defaultColors;
    
    // RepaintBoundary isolates this widget's repaints from the rest of the tree
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: _beginAlignment.value,
                end: _endAlignment.value,
              ),
              borderRadius: widget.borderRadius,
              boxShadow: [
                // Primary glow shadow
                BoxShadow(
                  color: colors.first.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                // Secondary glow for depth
                BoxShadow(
                  color: colors.last.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child, // Child is NOT rebuilt on animation tick
      ),
    );
  }
}
