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
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();
  List<int> _distanceIndexes = [];
  T? hoveredItem;

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

  double _getScaleValue(int index) {
    if (_distanceIndexes.isEmpty) {
      return 1.0;
    }

    if (_distanceIndexes[index] == 0) {
      return 1.4;
    }

    if (_distanceIndexes[index] == 1) {
      return 1.3;
    }

    if (_distanceIndexes[index] == 2) {
      return 1.2;
    }

    if (_distanceIndexes[index] == 3) {
      return 1.1;
    }

    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items
            .asMap()
            .entries
            .map(
              (e) => Draggable(
                feedback: widget.builder(e.value),
                child: MouseRegion(
                  onEnter: (event) => print('enter'),
                  onExit: (event) => _onExit(),
                  onHover: (event) => _onHover(e.value),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: _getScaleValue(e.key),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: widget.builder(e.value),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
