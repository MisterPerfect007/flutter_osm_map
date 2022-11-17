import 'package:flutter/material.dart';

import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';

import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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

  //
  GeoPoint? destination;
  //
  GeoPoint? lastUserPoint;

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
                backgroundColor: Colors.white,
                onPressed: goToLocation,
                child: const Icon(
                  Icons.location_searching,
                  color: Colors.blue,
                ),
              ),
              if (pickerStage == PositionPicker.p0)
                FloatingActionButton(
                  backgroundColor: Colors.blue,
                  onPressed: () async {
                    ////Show the picker
                    await controller.advancedPositionPicker();
                    await goToLocation();
                    setState(() {
                      pickerStage = PositionPicker.start;
                    });
                  },
                  child: const Icon(Icons.add),
                ),
              if (pickerStage == PositionPicker.start) fabPickerStart(),
              if (pickerStage == PositionPicker.end) fabPickerEnd(),
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
          onMapIsReady: (p0) async {
            await goToLocation();
          },
        ));
  }

  FloatingActionButton fabPickerStart() {
    return FloatingActionButton(
      backgroundColor: Colors.green,
      onPressed: () async {
        ////Show the picker
        GeoPoint p =
            await controller.getCurrentPositionAdvancedPositionPicker();
        //
        setState(() {
          destination = p;
        });
        /////road
        final userP = await userLocation();
        RoadInfo roadInfo = await controller
            .drawRoad(
          userP,
          p,
          roadType: RoadType.car,
          roadOption: const RoadOption(
            roadWidth: 10,
            roadColor: Colors.blue,
            showMarkerOfPOI: false,
            zoomInto: true,
          ),
        )
            .then((roadInfo) async {
          if (roadInfo.distance != 0.0 && roadInfo.duration != 0.0) {
            Get.snackbar(
                "Distance: ${roadInfo.distance!.toStringAsFixed(2)} Km",
                "Estimation de durée: ${roadInfo.duration} secondes",
                duration: const Duration(seconds: 8));
            await controller.addMarker(
              p,
              markerIcon: const MarkerIcon(
                  icon: Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 80,
              )),
            );
            setState(() {
              pickerStage = PositionPicker.end;
            });
            await controller.setZoom(zoomLevel: 17);
          } else {
            setState(() {
              pickerStage = PositionPicker.p0;
            });
            Get.snackbar(
              "Error ",
              "Vérifier votre connection à internet"
            );
          }
          
          return roadInfo;
        });

      },
      child: const Icon(Icons.add_location),
    );
  }

  FloatingActionButton fabPickerEnd() {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      onPressed: () async {
        //delete road
        await controller.removeLastRoad();
        if (destination != null) await controller.removeMarker(destination!);
        goToLocation();
        setState(() {
          pickerStage = PositionPicker.p0;
        });
      },
      child: const Icon(Icons.close),
    );
  }

  Future<void> goToLocation() async {
    final position = await determinePosition();
    final point =
        GeoPoint(latitude: position.latitude, longitude: position.longitude);
    await controller.goToLocation(point);
    await controller.setZoom(zoomLevel: 17);
    if (lastUserPoint != null) await controller.removeMarker(lastUserPoint!);
    lastUserPoint = point;
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

Future<GeoPoint> userLocation() async {
  final position = await determinePosition();
  return GeoPoint(latitude: position.latitude, longitude: position.longitude);
}

enum PositionPicker { p0, start, end }
