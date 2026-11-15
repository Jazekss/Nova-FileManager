import 'package:flutter/widgets.dart';

/// Page physics for photo pagers: a swipe must travel ~5 mm before the
/// page starts moving, so a pinch whose fingers wander sideways doesn't
/// flip to the next/previous photo.
class SteadyPagePhysics extends PageScrollPhysics {
  const SteadyPagePhysics({super.parent});

  @override
  SteadyPagePhysics applyTo(ScrollPhysics? ancestor) =>
      SteadyPagePhysics(parent: buildParent(ancestor));

  @override
  double get dragStartDistanceMotionThreshold => 32;
}

/// Counts fingers on the pager: with two or more down (a pinch) the
/// pager must not scroll at all. Calls [onChanged] with the count.
class PointerCounter extends StatefulWidget {
  const PointerCounter({
    super.key,
    required this.onChanged,
    required this.child,
  });

  final void Function(int pointers) onChanged;
  final Widget child;

  @override
  State<PointerCounter> createState() => _PointerCounterState();
}

class _PointerCounterState extends State<PointerCounter> {
  final Set<int> _down = {};

  void _update() => widget.onChanged(_down.length);

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _down.add(e.pointer);
      _update();
    },
    onPointerUp: (e) {
      _down.remove(e.pointer);
      _update();
    },
    onPointerCancel: (e) {
      _down.remove(e.pointer);
      _update();
    },
    child: widget.child,
  );
}
