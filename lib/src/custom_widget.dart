part of 'custom_layer.dart';

class MapboxCustomItem {
  final LatLng coordinate;
  final Widget child;
  final Size? size;

  MapboxCustomItem({
    required this.coordinate,
    required this.child,
    this.size,
  });
}

class MapboxCustomWidget extends StatefulWidget {
  final Point initialPosition;
  final LatLng coordinate;
  final void Function(MapboxCustomWidgetState) addMarkerState;
  final Widget child;
  final Size? size;
  MapboxCustomWidget({
    Key? key,
    required this.initialPosition,
    required this.coordinate,
    required this.addMarkerState,
    required this.child,
    this.size,
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<MapboxCustomWidget> createState() {
    final state = MapboxCustomWidgetState(initialPosition);
    addMarkerState(state);
    return state;
  }
}

class MapboxCustomWidgetState extends State<MapboxCustomWidget> {
  Point _position;

  MapboxCustomWidgetState(this._position);

  void updatePosition(Point<num> point) {
    setState(() {
      _position = point;
    });
  }

  LatLng getCoordinate() {
    return widget.coordinate;
  }

  Widget _buildPositioned(double width, double height) {
    var ratio = 1.0;

    //web does not support Platform._operatingSystem
    if (!kIsWeb) {
      // iOS returns logical pixel while Android returns screen pixel
      ratio = Platform.isIOS ? 1.0 : MediaQuery.of(context).devicePixelRatio;
    }
    return Positioned(
      left: _position.x / ratio - width / 2,
      top: _position.y / ratio - height / 2,
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size != null) {
      return _buildPositioned(
        widget.size!.width,
        widget.size!.height,
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) => _buildPositioned(
          constraints.maxWidth,
          constraints.maxHeight,
        ),
      );
    }
  }
}
