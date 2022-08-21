part of 'mapbox_widget_layer.dart';

class MapboxWidgetScreenPosition {
  final Point screenPosition;
  final double zoom;
  final double bearing;
  final double tilt;

  MapboxWidgetScreenPosition({
    required this.screenPosition,
    required this.zoom,
    required this.bearing,
    required this.tilt,
  });
}

typedef MapboxWidgetBuilderFunction = Widget Function(
  BuildContext context,
  MapboxWidgetScreenPosition screenPosition,
);

class MapboxItemBuilder {
  final LatLng coordinate;
  final Size? size;
  final MapboxWidgetBuilderFunction builder;

  MapboxItemBuilder({
    required this.builder,
    required this.coordinate,
    this.size,
  });
}

class MapboxItem extends MapboxItemBuilder {
  final Widget child;

  MapboxItem({
    required this.child,
    required super.coordinate,
    super.size,
  }) : super(
          builder: (_, __) {
            return child;
          },
        );
}

class MapboxAutoTransformItem extends MapboxItemBuilder {
  final Widget child;
  final bool zoomEnabled;
  final bool bearingEnabled;
  final bool tiltEnabled;
  final double zoomFactor;
  final double zoomBase;

  static _expZoom(double factor, double zoom, double anchor) =>
      pow(factor, zoom - anchor);

  MapboxAutoTransformItem({
    required this.child,
    required super.coordinate,
    super.size,
    this.zoomEnabled = true,
    this.bearingEnabled = true,
    this.tiltEnabled = true,
    this.zoomFactor = 2,
    this.zoomBase = 18,
  }) : super(builder: (context, screenPosition) {
          return Transform(
            child: child,
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..rotateX(screenPosition.tilt / 360 * (2 * pi))
              ..rotateZ(-screenPosition.bearing / 360 * (2 * pi))
              ..scale(
                _expZoom(zoomFactor, screenPosition.zoom, zoomBase),
                _expZoom(zoomFactor, screenPosition.zoom, zoomBase),
              ),
          );
        });
}

class MapboxWidget extends StatefulWidget {
  final MapboxWidgetScreenPosition initialScreenPosition;
  final LatLng coordinate;
  final void Function(MapboxWidgetState) addMarkerState;
  final MapboxWidgetBuilderFunction childBuilder;
  final Size? size;

  MapboxWidget({
    Key? key,
    required this.initialScreenPosition,
    required this.coordinate,
    required this.addMarkerState,
    required this.childBuilder,
    this.size,
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<MapboxWidget> createState() {
    final state = MapboxWidgetState();
    addMarkerState(state);
    return state;
  }
}

class MapboxWidgetState extends State<MapboxWidget> {
  late MapboxWidgetScreenPosition _screenPosition;

  @override
  void initState() {
    _screenPosition = widget.initialScreenPosition;
    super.initState();
  }

  void updatePosition(MapboxWidgetScreenPosition screenPosition) {
    setState(() {
      _screenPosition = screenPosition;
    });
  }

  LatLng getCoordinate() {
    return widget.coordinate;
  }

  Widget _buildPositioned(BuildContext context, double width, double height) {
    var ratio = 1.0;

    //web does not support Platform._operatingSystem
    if (!kIsWeb) {
      // iOS returns logical pixel while Android returns screen pixel
      ratio = Platform.isIOS ? 1.0 : MediaQuery.of(context).devicePixelRatio;
    }
    return Positioned(
      left: _screenPosition.screenPosition.x / ratio - width / 2,
      top: _screenPosition.screenPosition.y / ratio - height / 2,
      child: widget.childBuilder(context, _screenPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size != null) {
      return _buildPositioned(
        context,
        widget.size!.width,
        widget.size!.height,
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) => _buildPositioned(
          context,
          constraints.maxWidth,
          constraints.maxHeight,
        ),
      );
    }
  }
}
