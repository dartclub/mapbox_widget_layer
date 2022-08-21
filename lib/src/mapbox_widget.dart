part of 'mapbox_widget_layer.dart';

/// class that stores the updated [screenPosition], [zoom], [bearing], and [tilt], during movements of the underlying [MapboxMap].
///
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

/// Callback used in the [builder] attribute in [MapboxItemBuilder].
/// Exposes the current [BuildContext] and [MapboxWidgetScreenPosition].
///
typedef MapboxItemBuilderCallback = Widget Function(
  BuildContext context,
  MapboxWidgetScreenPosition screenPosition,
);

/// Exposes all attributes to manually control rendering of the widget:
/// [screenPosition] [zoom], [bearing], and [tilt] in a [builder]-closure
///  to reactively build widgets according to the exposed attributes.
///
class MapboxItemBuilder {
  final LatLng coordinate;
  final Size? size;
  final MapboxItemBuilderCallback builder;

  MapboxItemBuilder({
    required this.builder,
    required this.coordinate,
    this.size,
  });
}

/// Does not expose attributes to customize rendering.
///
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

/// Auto-transforms rendering, based on the [zoom], [bearing], and [tilt] of the underlying [MapboxMap].
/// Allows for manual control of the [zoomBase]
/// (zoom level at which the scale of the widget should match the [size] in pixels),
/// and [zoomExpFactor], which is the exponential base for the interpolation between zoom levels.
/// Also allows for enabling/disabling of the different attributes ([zoomEnabled], [bearingEnabled], [tiltEnabled]).
///
class MapboxAutoTransformItem extends MapboxItemBuilder {
  final Widget child;
  final bool zoomEnabled;
  final bool bearingEnabled;
  final bool tiltEnabled;
  final double zoomExpBase;
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
    this.zoomExpBase = 2,
    this.zoomBase = 18,
  }) : super(builder: (context, screenPosition) {
          var matrix = Matrix4.identity();
          if (tiltEnabled) {
            matrix.rotateX(screenPosition.tilt / 360 * (2 * pi));
          }
          if (bearingEnabled) {
            matrix.rotateZ(-screenPosition.bearing / 360 * (2 * pi));
          }
          if (zoomEnabled) {
            matrix.scale(
              _expZoom(zoomExpBase, screenPosition.zoom, zoomBase),
              _expZoom(zoomExpBase, screenPosition.zoom, zoomBase),
            );
          }
          return Transform(
            child: child,
            alignment: FractionalOffset.center,
            transform: matrix,
          );
        });
}

/// Used internally to control rendering and transformation of the widgets
class MapboxWidget extends StatefulWidget {
  final MapboxWidgetScreenPosition initialScreenPosition;
  final LatLng coordinate;
  final void Function(MapboxWidgetState) addMarkerState;
  final MapboxItemBuilderCallback childBuilder;
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
