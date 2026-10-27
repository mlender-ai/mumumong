// The V2 wordmark: the name set in the editorial serif, with three memory
// dots after it. The dots print once when the wordmark first appears.
import 'package:flutter/material.dart';

import '../design/tokens.dart';

class V2Wordmark extends StatefulWidget {
  const V2Wordmark({
    super.key,
    this.size = 19,
    this.color = V2Color.ink,
    this.animate = false,
  });

  final double size;
  final Color color;
  final bool animate;

  @override
  State<V2Wordmark> createState() => _V2WordmarkState();
}

class _V2WordmarkState extends State<V2Wordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _print = AnimationController(
    vsync: this,
    duration: V2Motion.gather,
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (V2Motion.reduced(context)) {
          _print.value = 1;
        } else {
          _print.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _print.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '무무몽',
      header: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '무무몽',
            style: V2Type.title.copyWith(
              fontSize: widget.size,
              letterSpacing: widget.size * .06,
              color: widget.color,
              height: 1,
            ),
          ),
          SizedBox(width: widget.size * .32),
          AnimatedBuilder(
            animation: _print,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Opacity(
                    opacity: ((_print.value - i * .22) / .34).clamp(0.0, 1.0),
                    child: Container(
                      width: widget.size * .2,
                      height: widget.size * .2,
                      margin: EdgeInsets.only(right: widget.size * .12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 2 ? V2Color.sky500 : widget.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
