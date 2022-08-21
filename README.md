# mapbox_widget_layer

!! May be unstable and have bad performance !!
Custom Flutter Widgets on top of a Mapbox Map (package [mapbox_gl](https://pub.dev/packages/mapbox_gl)). Exposes builders to reactively build widgets based on screen position, zoom, bearing, and tilt.


https://user-images.githubusercontent.com/10634693/185800406-314cf4d4-128f-4c16-b5cf-e97035e15664.mov


Heavily inspired by the example here: [flutter-mapbox-gl/maps > custom markers](https://github.com/flutter-mapbox-gl/maps/blob/master/example/lib/custom_marker.dart)

## Usage

- Install [mapbox_gl](https://pub.dev/packages/mapbox_gl)
- Create a new widget with a `Stack` widget that contains a `MapboxMap` and the `MapboxWidgetLayer`

There are three options for widget rendering:

1) `MapboxItemBuilder` – exposes all attributes to manually control rendering of the widget: `screenPosition` `zoom`, `bearing`, and `tilt` in a `builder`-closure to reactively build widgets according to the exposed attributes.
    Example usage:  

    ```dart
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
    ```

2) `MapboxItem` – does not expose options to customize rendering.
    Example usage:

    ```dart
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
    ```

3) `MapboxAutoTransformItem` – auto-adjusts rendering, based on the `zoom`, `bearing`, and `tilt`. Allows for manual control of the `zoomBase` (zoom level at which the scale of the widget should match the `size` in pixels), and `zoomExpFactor`, which is the exponential base for the interpolation between zoom levels.
    Example usage:

    ```dart
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
    ```

### Full example can be found in file `./example/main.dart` [HERE](https://pub.dev/packages/mapbox_widget_layer/example)
