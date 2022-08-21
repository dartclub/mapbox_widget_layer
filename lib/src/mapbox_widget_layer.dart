import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

part 'mapbox_widget.dart';

/// Exposes methods, to dynamically add/update/delete items during runtime.
///
class MapboxWidgetLayerController {
  final Future<int> Function(MapboxItemBuilder item) addItem;
  final Future<int> Function(int index, MapboxItemBuilder) updateItem;
  final Future<void> Function(int index) deleteItem;

  MapboxWidgetLayerController({
    required this.addItem,
    required this.deleteItem,
    required this.updateItem,
  });
}

/// Renders the custom widget layer.
/// Expects a [MapboxMapController], wrapped in a [Future], to access the map movements of the underlying [MapboxMap].
/// [onMapInteractive] provides a [MapboxWidgetLayerController], which Exposes methods
/// to dynamically add/update/delete items during runtime
///
/// Usage:
///
/// ```dart
///    class MapboxWithWidgetLayer extends StatelessWidget {
///      MapboxWithWidgetLayer({Key? key}) : super(key: key);
///      final completer = Completer<MapboxMapController>();
///
///      @override
///      Widget build(BuildContext context) {
///        return Stack(
///          children: [
///            MapboxMap(
///              accessToken: 'ACCESS TOKEN',
///              initialCameraPosition: CameraPosition(target: LatLng(0, 0)),
///              onMapCreated: (controller) => completer.complete(controller),
///            ),
///            MapboxWidgetLayer(
///              onMapInteractive: (contorller) {},
///              controllerFuture: completer.future,
///              items: [
///                // ...
///              ],
///            ),
///          ],
///        );
///      }
///    }
/// ```
///
class MapboxWidgetLayer extends StatefulWidget {
  final Future<MapboxMapController> controllerFuture;
  final ValueChanged<MapboxWidgetLayerController>? onMapInteractive;
  final List<MapboxItemBuilder> items;
  const MapboxWidgetLayer({
    Key? key,
    required this.controllerFuture,
    required this.items,
    this.onMapInteractive,
  }) : super(key: key);

  @override
  State<MapboxWidgetLayer> createState() => _MapboxWidgetLayerState();
}

class _MapboxWidgetLayerState extends State<MapboxWidgetLayer> {
  final List<MapboxWidget> _markers = [];
  final List<MapboxWidgetState> _markerStates = [];
  late final MapboxMapController _mapController;

  @override
  void initState() {
    widget.controllerFuture.then((controller) => _onMapCreated(controller));
    super.initState();
  }

  Future<void> _deleteItem(int index) async {
    setState(() {
      _markers.removeAt(index);
      _markerStates.removeAt(index);
    });
  }

  Future<int> _updateItem(
    int index,
    MapboxItemBuilder newItem,
  ) async {
    var wid = await _newWidgetFromItem(newItem, (state) {
      _markerStates[index] = state;
    });
    setState(() {
      _markers[index] = wid;
    });

    return index;
  }

  Future<MapboxWidget> _newWidgetFromItem(
    MapboxItemBuilder item,
    Function(MapboxWidgetState state) updateMarkerState,
  ) async {
    var val = await _mapController.toScreenLocation(item.coordinate);
    var cameraPos = _mapController.cameraPosition!;
    var point = Point<double>(val.x as double, val.y as double);

    return MapboxWidget(
      size: item.size,
      childBuilder: item.builder,
      coordinate: item.coordinate,
      initialScreenPosition: MapboxWidgetScreenPosition(
        screenPosition: point,
        zoom: cameraPos.zoom,
        bearing: cameraPos.bearing,
        tilt: cameraPos.tilt,
      ),
      addMarkerState: updateMarkerState,
    );
  }

  Future<int> _addItem(MapboxItemBuilder item) async {
    var wid = await _newWidgetFromItem(item, (state) {
      _markerStates.add(state);
    });
    setState(() {
      _markers.add(wid);
    });
    return _markers.length - 1;
  }

  void _mapListenerClosure() {
    if (_mapController.isCameraMoving) {
      _updateMarkerPosition();
    }
  }

  void _onMapCreated(MapboxMapController controller) async {
    _mapController = controller;
    _mapController.addListener(_mapListenerClosure);

    for (var item in widget.items) {
      await _addItem(item);
    }

    if (widget.onMapInteractive != null) {
      widget.onMapInteractive!(
        MapboxWidgetLayerController(
          addItem: _addItem,
          deleteItem: _deleteItem,
          updateItem: _updateItem,
        ),
      );
    }
  }

  // ignore: unused_element
  void _onCameraIdleCallback() {
    _updateMarkerPosition();
  }

  void _updateMarkerPosition() {
    final coordinates = <LatLng>[];

    for (final markerState in _markerStates) {
      coordinates.add(markerState.getCoordinate());
    }

    _mapController.toScreenLocationBatch(coordinates).then((points) {
      var cameraPos = _mapController.cameraPosition!;
      _markerStates.asMap().forEach((i, value) {
        _markerStates[i].updatePosition(
          MapboxWidgetScreenPosition(
            screenPosition: points[i],
            zoom: cameraPos.zoom,
            bearing: cameraPos.bearing,
            tilt: cameraPos.tilt,
          ),
        );
      });
    });
  }

  // ignore: unused_element
  void _measurePerformance() {
    final trial = 10;
    final batches = [500, 1000, 1500, 2000, 2500, 3000];
    var results = <int, List<double>>{};
    for (final batch in batches) {
      results[batch] = [0.0, 0.0];
    }

    _mapController.toScreenLocation(LatLng(0, 0));
    Stopwatch sw = Stopwatch();

    for (final batch in batches) {
      for (var i = 0; i < trial; i++) {
        sw.start();
        var list = <Future<Point<num>>>[];
        for (var j = 0; j < batch; j++) {
          var p = _mapController
              .toScreenLocation(LatLng(j.toDouble() % 80, j.toDouble() % 300));
          list.add(p);
        }
        Future.wait(list);
        sw.stop();
        results[batch]![0] += sw.elapsedMilliseconds;
        sw.reset();
      }

      //
      // batch
      //
      for (var i = 0; i < trial; i++) {
        sw.start();
        var param = <LatLng>[];
        for (var j = 0; j < batch; j++) {
          param.add(LatLng(j.toDouble() % 80, j.toDouble() % 300));
        }
        Future.wait([_mapController.toScreenLocationBatch(param)]);
        sw.stop();
        results[batch]![1] += sw.elapsedMilliseconds;
        sw.reset();
      }

      debugPrint(
          'batch=$batch,primitive=${results[batch]![0] / trial}ms, batch=${results[batch]![1] / trial}ms');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: _markers,
      ),
    );
  }
}
