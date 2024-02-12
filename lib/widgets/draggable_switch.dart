import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DraggableResizableWidget extends StatefulWidget {
  final Widget child;
  final Function(DragUpdateDetails)? onDragUpdate;

  DraggableResizableWidget({Key? key, required this.child, this.onDragUpdate}) : super(key: key);

  @override
  _DraggableResizableWidgetState createState() => _DraggableResizableWidgetState();
}

class _DraggableResizableWidgetState extends State<DraggableResizableWidget> {
  Offset position = Offset(0.0, 0.0);
  double width = 200;
  double height = 200;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          position += details.delta;
          if (widget.onDragUpdate != null) {
            widget.onDragUpdate!(details);
          }
        });
      },
      child: Listener(
        onPointerHover: (event) {
          // Change cursor on hover
          if (event.kind == PointerDeviceKind.mouse) {
            // MouseCursor cursor = SystemMouseCursors.click;
            // SystemMouseCursors.set(cursor);
          }
        },
        child: Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    width += details.delta.dx;
                    height += details.delta.dy;
                  });
                },
                child: Container(
                  width: width,
                  height: height,
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
