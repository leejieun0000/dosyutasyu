import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

class BikeStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  int availableBikes;

  BikeStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.availableBikes,
  });

  factory BikeStation.fromJson(Map<String, dynamic> json) {
    return BikeStation(
      id: json['id'],
      name: json['name'],
      latitude: double.parse(json['x_pos']),
      longitude: double.parse(json['y_pos']),
      address: json['address'],
      availableBikes: json['parking_count'],
    );
  }
}

class FreeRide extends StatefulWidget {
  @override
  _FreeRideState createState() => _FreeRideState();
}

class _FreeRideState extends State<FreeRide> {
  late GoogleMapController mapController;
  final Location location = Location();
  late Timer _timer;
  Duration _elapsedTime = Duration.zero;
  List<BikeStation> bikeStations = [];

  CameraPosition currentPosition = CameraPosition(
    target: LatLng(36.368549, 127.343738),
    zoom: 14,
  );

  bool isLoading = true;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startTimer();
    fetchBikeStations();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = Duration(seconds: timer.tick);
      });
    });
  }

  void _getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (_serviceEnabled != true) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        currentPosition = CameraPosition(
          target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
          zoom: 14,
        );

        isLoading = false;

        markers.add(
          Marker(
            markerId: MarkerId("currentLocation"),
            position: LatLng(currentLocation.latitude!, currentLocation.longitude!),
            infoWindow: InfoWindow(
              title: "현재 위치",
            ),
            rotation: currentLocation.heading!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });
    });
  }

  void _moveCameraToCurrentPosition() async {
    final LocationData _locationData = await location.getLocation();
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_locationData.latitude!, _locationData.longitude!),
          zoom: 14,
        ),
      ),
    );
  }

  Future<void> fetchBikeStations() async {
    final response = await http.get(
      Uri.parse('https://bikeapp.tashu.or.kr:50041/v1/openapi/station'),
      headers: {'api-token': '8drt984w1f467rzi'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(utf8.decode(response.bodyBytes));
      final results = jsonData['results'];
      List<BikeStation> stations = [];

      for (var result in results) {
        stations.add(BikeStation.fromJson(result));
      }

      setState(() {
        bikeStations = stations;
        _setMarkers(); // 마커 설정
      });
    } else {
      throw Exception('Failed to load bike stations');
    }
  }

  Future<BitmapDescriptor> _createMarkerIconWithCount(int count) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.orange;
    final int markerSize = 120;

    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      markerSize / 2.0,
      paint,
    );

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: '🚲',
      style: TextStyle(fontSize: 50),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((markerSize - textPainter.width) / 2, 10),
    );

    textPainter.text = TextSpan(
      text: count.toString(),
      style: TextStyle(
        fontSize: 40,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((markerSize - textPainter.width) / 2, markerSize / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(markerSize, markerSize);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _setMarkers() async {
    markers.clear();
    for (var station in bikeStations) {
      final BitmapDescriptor markerIcon = await _createMarkerIconWithCount(station.availableBikes);
      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: 'Available Bikes: ${station.availableBikes}',
          ),
          icon: markerIcon,
        ),
      );
    }
    setState(() {});
  }

  void _showReturnCompleteDialog() {
    final hours = _elapsedTime.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsedTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsedTime.inSeconds % 60).toString().padLeft(2, '0');
    final elapsedTimeStr = '$hours:$minutes:$seconds';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("반납완료!"),
          content: Text("반납이 완료되었습니다.\n이용 시간: $elapsedTimeStr"),
          actions: <Widget>[
            TextButton(
              child: Text("확인"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _elapsedTime.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsedTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsedTime.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: currentPosition,
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            zoomControlsEnabled: false,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showReturnCompleteDialog,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("반납하기"),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                AppBar(
                  title: Image.asset(
                    'assets/images/doshutashulogo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.white.withOpacity(0.4),
                  elevation: 4,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.white.withOpacity(0.8),
                    child: Text(
                      '이용 시간: $hours:$minutes:$seconds',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
