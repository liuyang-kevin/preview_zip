import 'package:flutter/material.dart';

enum SplitDirection { vertical, horizontal }

// gpt实现的页面分割
class SplitView extends StatefulWidget {
  final List<Widget> children;
  final SplitDirection direction;

  SplitView({required this.children, this.direction = SplitDirection.vertical});

  @override
  _SplitViewState createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late double _dividerPosition;
  late Size _containerSize;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _dividerPosition = 0.5; // 默认位置
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dividerPosition += details.primaryDelta! / _containerSize.width;
      if (_dividerPosition < 0.0) {
        _dividerPosition = 0.0;
      } else if (_dividerPosition > 1.0) {
        _dividerPosition = 1.0;
      }
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dividerPosition += details.primaryDelta! / _containerSize.height;
      if (_dividerPosition < 0.0) {
        _dividerPosition = 0.0;
      } else if (_dividerPosition > 1.0) {
        _dividerPosition = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerSize = constraints.biggest;
        return widget.direction == SplitDirection.vertical ? _buildVerticalSplitView() : _buildHorizontalSplitView();
      },
    );
  }

  Widget _buildVerticalSplitView() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _containerSize.width * _dividerPosition,
            child: widget.children[0],
          ),
          Positioned(
            left: _containerSize.width * _dividerPosition,
            top: 0,
            bottom: 0,
            right: 0,
            child: widget.children[1],
          ),
          Positioned(
            left: _containerSize.width * _dividerPosition - 4,
            top: 0,
            bottom: 0,
            width: 8,
            child: GestureDetector(
              onHorizontalDragUpdate: _onVerticalDragUpdate,
              child: Container(
                color: _isHovering ? Colors.grey.withOpacity(0.2) : Colors.transparent,
                child: Center(
                  child: Container(
                    width: 4,
                    height: _containerSize.height,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSplitView() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: _containerSize.height * _dividerPosition,
            child: widget.children[0],
          ),
          Positioned(
            left: 0,
            top: _containerSize.height * _dividerPosition,
            right: 0,
            bottom: 0,
            child: widget.children[1],
          ),
          Positioned(
            top: _containerSize.height * _dividerPosition - 4,
            left: 0,
            right: 0,
            height: 8,
            child: GestureDetector(
              onVerticalDragUpdate: _onHorizontalDragUpdate,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Container(
                  color: _isHovering ? Colors.grey.withOpacity(0.2) : Colors.transparent,
                  child: Center(
                    child: Container(
                      height: 4,
                      width: _containerSize.width,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('SplitView Example')),
      body: SplitView(
        direction: SplitDirection.horizontal,
        children: [
          Container(
            color: Colors.blue,
            child: Center(child: Text('Top Panel')),
          ),
          Container(
            color: Colors.green,
            child: Center(child: Text('Bottom Panel')),
          ),
        ],
      ),
    ),
  ));
}
