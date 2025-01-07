import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  final GlobalKey _rowKey = GlobalKey();

  late final List<T> _items = widget.items.toList();
  List<int> _distanceIndexes = [];
  bool _showAvaliableSpace = false;
  T? _dragingItem;
  int? _closestIndex;

  void _onExit() {
    setState(() => _distanceIndexes.clear());
  }

  void _onHover(T element) {
    final hoveredElementIndex = _items.indexOf(element);

    final dI = List.generate(
      _items.length,
      (index) => (index - hoveredElementIndex).abs(),
    );

    setState(() {
      _distanceIndexes = dI;
    });
  }

  void _calculateClosestItem(PointerEvent event) {
    final renderBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final rowWidth = renderBox.size.width;
    final localPosition = renderBox.globalToLocal(event.position);
    final sectionWidth = rowWidth / _items.length;

    final closestIndex =
        (localPosition.dx / sectionWidth).clamp(0, _items.length - 1).round();

    if (_closestIndex != closestIndex && _dragingItem != null) {
      setState(() {
        _closestIndex = closestIndex;
      });
    }
  }

  // $1 - scale $2 - horizontal padding
  (double, double) _getScaleAndPaddingValue(int index) {
    if (_distanceIndexes.isEmpty) {
      return (1.0, 0);
    }

    if (_distanceIndexes[index] == 0) {
      return (1.4, 8);
    }

    if (_distanceIndexes[index] == 1) {
      return (1.3, 5);
    }

    if (_distanceIndexes[index] == 2) {
      return (1.2, 3);
    }

    if (_distanceIndexes[index] == 3) {
      return (1.1, 1);
    }

    return (1.0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Listener(
        onPointerMove: (event) {
          setState(() => _showAvaliableSpace = true);
          _calculateClosestItem(event);
        },
        child: MouseRegion(
          onExit: (event) => setState(() {
            _showAvaliableSpace = false;
            _distanceIndexes.clear();
          }),
          child: Row(
            key: _rowKey,
            mainAxisSize: MainAxisSize.min,
            children: _items
                .asMap()
                .entries
                .map(
                  (e) => Draggable<int>(
                    data: e.key,
                    feedback: Transform.scale(
                        scale: _getScaleAndPaddingValue(e.key).$1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: _getScaleAndPaddingValue(e.key).$2),
                          child: widget.builder(e.value),
                        )),
                    onDragStarted: () => _dragingItem = e.value,
                    onDragEnd: (_) => _dragingItem = null,
                    childWhenDragging: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _showAvaliableSpace ? 64 : 0,
                      height: 0,
                    ),
                    child: MouseRegion(
                        onExit: (event) => _onExit(),
                        onHover: (event) => _onHover(e.value),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 1,
                            end: _getScaleAndPaddingValue(e.key).$1,
                          ),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      _getScaleAndPaddingValue(e.key).$2,
                                ),
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: widget.builder(e.value),
                              ),
                            );
                          },
                        )),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
