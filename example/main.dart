import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_widget_layer/mapbox_widget_layer.dart';

class MapboxWithWidgetLayer extends StatelessWidget {
  MapboxWithWidgetLayer({Key? key}) : super(key: key);
  final completer = Completer<MapboxMapController>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapboxMap(
          initialCameraPosition: CameraPosition(target: LatLng(0, 0)),
          onMapCreated: (controller) => completer.complete(controller),
        ),
        MapboxWidgetLayer(
          onMapInteractive: (contorller) {},
          controllerFuture: completer.future,
          items: [
            MapboxItem(
              coordinate: LatLng(0, 0),
              child: Text('Custom Label'),
            ),
          ],
        ),
      ],
    );
  }
}
