import 'dart:async';

import 'package:flutter/material.dart';
import 'package:full_example/credentials.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_widget_layer/mapbox_widget_layer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Widget Layer Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final completer = Completer<MapboxMapController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Widget Layer'),
      ),
      body: Stack(
        children: [
          MapboxMap(
            accessToken: accessToken, // create a credentials.dart file
            initialCameraPosition: const CameraPosition(
              target: LatLng(49.457647152564334, 11.076190602176172),
            ),
            onMapCreated: (controller) => completer.complete(controller),
          ),
          MapboxWidgetLayer(
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
                builder: (_, __) => Container(
                  height: 100,
                  width: 100,
                  color: Colors.blue[200],
                  child: const Center(child: Text('builder')),
                ),
                size: const Size(100, 100),
                coordinate:
                    const LatLng(49.457647152564334, 11.076190602176172),
              ),
              MapboxAutoTranslateItem(
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
      ),
    );
  }
}
