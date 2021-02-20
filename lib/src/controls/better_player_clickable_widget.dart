// Flutter imports:
import 'package:flutter/material.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final double radius;
  final void Function() onTap;
  final void Function() onDoubleTap;

  const BetterPlayerMaterialClickableWidget(
      {Key key,
      @required this.onTap,
      this.onDoubleTap,
      @required this.child,
      this.radius = 60})
      : assert(onTap != null),
        assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      color: Colors.black26,
      child: InkWell(
        onDoubleTap: onDoubleTap,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
