import 'package:flutter/material.dart';

import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TheMap(),
    );
  }
}

class TheMap extends StatefulWidget {
  const TheMap({super.key});

  @override
  State<TheMap> createState() => _TheMapState();
}

class _TheMapState extends State<TheMap> {
  PositionPicker pickerStage = PositionPicker.p0;

  final controller = MapController.customLayer(
    initMapWithUserPosition: false,
    initPosition: GeoPoint(
      latitude: 5.384099735338577,
      longitude: -4.025423983538768,
    ),
    customTile: CustomTile(
      sourceName: "opentopomap",
      tileExtension: ".png",
      minZoomLevel: 2,
      maxZoomLevel: 19,
      urlsServers: [
        TileURLs(
          url: "https://tile.opentopomap.org/",
          subdomains: [],
        )
      ],
      tileSize: 256,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // await Future.delayed(const Duration(seconds: 3));
      final point = await controller.myLocation();
      await controller.goToLocation(point);
      // controller.drawRoad(start, end)
      // print(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(
                onPressed: goToLocation,
                child: const Icon(Icons.location_searching),
              ),
              if (pickerStage == PositionPicker.p0)
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      pickerStage = PositionPicker.start;
                    });
                    await controller.advancedPositionPicker();
                  },
                  child: const Text("Add Destination"),
                ),
              if (pickerStage == PositionPicker.start)
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    await controller.cancelAdvancedPositionPicker();
                    setState(() {
                      pickerStage = PositionPicker.p0;
                    });
                  },
                  child: const Icon(Icons.cancel),
                ),
              if (pickerStage == PositionPicker.start)
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: () async {
                    GeoPoint p = await controller
                        .getCurrentPositionAdvancedPositionPicker();
                    await controller.addMarker(
                      p,
                      markerIcon: const MarkerIcon(
                          icon: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 100,
                      )),
                    );
                    print(p);
                    setState(() {
                      pickerStage = PositionPicker.end;
                    });
                  },
                  child: const Text("Ok"),
                ),
              if (pickerStage == PositionPicker.end)
                FloatingActionButton(
                  backgroundColor: Colors.blue,
                  onPressed: () async {
                    GeoPoint p = await controller
                        .getCurrentPositionAdvancedPositionPicker();
                    await controller.removeMarker(p);
                    await controller.addMarker(
                      p,
                      markerIcon: MarkerIcon(
                        iconWidget: Container(
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(1000))),
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(1000))),
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              Icons.location_on,
                              size: 100,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    );
                    print(p);
                    /* setState(() {
                      pickerStage = PositionPicker.end;
                    }); */
                  },
                  child: const Icon(Icons.arrow_forward),
                ),
            ],
          ),
        ),
        body: OSMFlutter(
          controller: controller,
          trackMyPosition: false,
          initZoom: 12,
          stepZoom: 1.0,
          userLocationMarker: UserLocationMaker(
            personMarker: const MarkerIcon(
              icon: Icon(
                Icons.location_history_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            directionArrowMarker: const MarkerIcon(
              icon: Icon(
                Icons.double_arrow,
                size: 48,
              ),
            ),
          ),
          roadConfiguration: RoadConfiguration(
            startIcon: const MarkerIcon(
              icon: Icon(
                Icons.person,
                size: 64,
                color: Colors.brown,
              ),
            ),
            roadColor: Colors.yellowAccent,
          ),
          markerOption: MarkerOption(
              defaultMarker: const MarkerIcon(
            icon: Icon(
              Icons.person_pin_circle,
              color: Colors.blue,
              size: 56,
            ),
          )),
        ));
  }

  void goToLocation() async {
    final point = await controller.myLocation();
    await controller.goToLocation(point);
    await controller.setZoom(zoomLevel: 17);
    await controller.removeMarker(point);
    await controller.addMarker(
      point,
      markerIcon: MarkerIcon(
        iconWidget: Container(
          decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(1000))),
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                borderRadius: const BorderRadius.all(Radius.circular(1000))),
            padding: const EdgeInsets.all(10),
            child: const Icon(
              Icons.location_on,
              size: 100,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}

enum PositionPicker { p0, start, end }
