import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'home_screen.dart';

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

class DestRiding extends StatefulWidget {
  const DestRiding({Key? key}) : super(key: key);

  @override
  _DestRidingState createState() => _DestRidingState();
}

class _DestRidingState extends State<DestRiding> {
  late GoogleMapController mapController;
  final Location location = Location();
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
    fetchBikeStations();
  }

  void _getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
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
    setState(() {
      currentPosition = CameraPosition(
        target: LatLng(_locationData.latitude!, _locationData.longitude!),
        zoom: 14,
      );
      isLoading = false;
    });

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(currentPosition),
    );
  }

  void _returnBike() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return RotatedBox(
              quarterTurns: 0,
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
            );
          },
        ),
        title: Text(
          "목적지 이동",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFBF30),
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: currentPosition,
            markers: markers,
            onMapCreated: (controller) => mapController = controller,
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _returnBike,
              child: Text("반납하기"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
