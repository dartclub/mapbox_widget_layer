import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

part 'custom_widget.dart';

class MapboxCustomWidgetLayer extends StatefulWidget {
  final Future<MapboxMapController> controllerFuture;
  final List<MapboxCustomItem> items;
  const MapboxCustomWidgetLayer({
    Key? key,
    required this.controllerFuture,
    required this.items,
  }) : super(key: key);

  @override
  State<MapboxCustomWidgetLayer> createState() =>
      _MapboxCustomWidgetLayerState();
}

class _MapboxCustomWidgetLayerState extends State<MapboxCustomWidgetLayer> {
  final List<MapboxCustomWidget> _markers = [];
  final List<MapboxCustomWidgetState> _markerStates = [];
  late final MapboxMapController _mapController;

  @override
  void initState() {
    widget.controllerFuture.then((controller) => _onMapCreated(controller));
    super.initState();
  }

  void _addMarkerStates(MapboxCustomWidgetState markerState) {
    _markerStates.add(markerState);
  }

  void _onMapCreated(MapboxMapController controller) async {
    _mapController = controller;
    controller.addListener(() {
      if (controller.isCameraMoving) {
        _updateMarkerPosition();
      }
    });

    for (var item in widget.items) {
      _mapController.toScreenLocation(item.coordinate).then((value) {
        var point = Point<double>(value.x as double, value.y as double);
        _addMarker(
          MapboxCustomWidget(
            size: item.size,
            child: item.child,
            coordinate: item.coordinate,
            initialPosition: point,
            addMarkerState: _addMarkerStates,
          ),
        );
      });
    }
  }

  void _onCameraIdleCallback() {
    _updateMarkerPosition();
  }

  void _updateMarkerPosition() {
    final coordinates = <LatLng>[];

    for (final markerState in _markerStates) {
      coordinates.add(markerState.getCoordinate());
    }

    _mapController.toScreenLocationBatch(coordinates).then((points) {
      _markerStates.asMap().forEach((i, value) {
        _markerStates[i].updatePosition(points[i]);
      });
    });
  }

  void _addMarker(MapboxCustomWidget marker) {
    setState(() {
      _markers.add(marker);
    });
  }

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
