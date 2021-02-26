// Flutter imports:
import 'package:flutter/material.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final void Function() onTap;
  final void Function() onDoubleTap;

  const BetterPlayerMaterialClickableWidget(
      {Key key,
      @required this.onTap,
      this.onDoubleTap,
      this.color = Colors.black26,
      @required this.child,
      this.radius = 60})
      :

        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      color: color,
      child: InkWell(
        onDoubleTap: onDoubleTap,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
