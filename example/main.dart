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
              child: Container(
                height: 100,
                width: 100,
                color: Colors.red[200],
                child: const Center(child: Text('item')),
              ),
              size: const Size(100, 100),
              coordinate: const LatLng(49.45800162760231, 11.076150534247994),
            ),
            MapboxItemBuilder(
              builder: (context, screenPosition) {
                debugPrint('${screenPosition.screenPosition}');
                debugPrint('${screenPosition.zoom}');
                debugPrint('${screenPosition.bearing}');
                debugPrint('${screenPosition.tilt}');
                return Container(
                  height: 100,
                  width: 100,
                  color: Colors.blue[200],
                  child: const Center(child: Text('builder')),
                );
              },
              size: const Size(100, 100),
              coordinate: const LatLng(49.457647152564334, 11.076190602176172),
            ),
            MapboxAutoTransformItem(
              child: Container(
                height: 100,
                width: 100,
                color: Colors.green[200],
                child: const Center(child: Text('auto')),
              ),
              size: const Size(100, 100),
              coordinate: const LatLng(49.45750295375467, 11.076125061775054),
            ),
          ],
        ),
      ],
    );
  }
}
