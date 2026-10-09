import 'package:flutter/material.dart';

/// Curva "ease-out" fuerte para UI (cubic-bezier(0.23, 1, 0.32, 1)).
const Curve kEaseOut = Cubic(0.23, 1, 0.32, 1);

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Da feedback de presión (escala 0.97) a cualquier elemento tocable.
/// Solo presentación: delega el toque a [onTap] sin cambiar su comportamiento.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !reduce ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _down ? 100 : 160),
        curve: kEaseOut,
        child: widget.child,
      ),
    );
  }
}

/// Aparición suave (fade + desplazamiento corto) con retraso escalonado por
/// posición. Solo anima los primeros [maxStaggered] elementos para que lo que
/// entra al hacer scroll no llegue tarde.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  static const int maxStaggered = 8;
  static const int _stepMs = 45;
  static const int _durationMs = 240;

  const FadeSlideIn({super.key, required this.child, required this.index});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    final delay = widget.index.clamp(0, FadeSlideIn.maxStaggered) * FadeSlideIn._stepMs;
    final total = delay + FadeSlideIn._durationMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / total, 1, curve: kEaseOut),
    );
    _opacity = curve;
    _offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curve);
    if (widget.index < FadeSlideIn.maxStaggered) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
