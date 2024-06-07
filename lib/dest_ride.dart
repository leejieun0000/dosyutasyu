import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dest_riding.dart'; // DestRiding 화면을 import

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

class DestinationRide extends StatefulWidget {
  const DestinationRide({Key? key}) : super(key: key);

  @override
  _DestinationRideState createState() => _DestinationRideState();
}

class _DestinationRideState extends State<DestinationRide> {
  late GoogleMapController mapController;
  final Location location = Location();
  List<BikeStation> bikeStations = [];
  CameraPosition currentPosition = CameraPosition(
    target: LatLng(36.368549, 127.343738),
    zoom: 14,
  );

  bool isLoading = true;
  Set<Marker> markers = {};
  BikeStation? startStation;
  BikeStation? endStation;

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
    /*
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(currentPosition),
    );
    */
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
        _setMarkers();
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
          onTap: () => _showStationOptions(station),
        ),
      );
    }
    setState(() {});
  }

  void _showStationOptions(BikeStation station) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.directions_bike),
              title: Text('출발지로 설정'),
              onTap: () {
                setState(() {
                  startStation = station;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.flag),
              title: Text('도착지로 설정'),
              onTap: () {
                setState(() {
                  endStation = station;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _calculateDistanceAndTime() {
    if (startStation == null || endStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출발지와 도착지를 모두 선택하세요')),
      );
      return;
    }

    final double distanceInMeters = _calculateDistance(
      startStation!.latitude,
      startStation!.longitude,
      endStation!.latitude,
      endStation!.longitude,
    );

    final double speedInMetersPerMinute = 200; // 가정된 자전거 속도 (200m/min)
    final double timeInMinutes = distanceInMeters / speedInMetersPerMinute;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('두 정류소 간의 거리'),
          content: Text(
              '거리: ${distanceInMeters.toStringAsFixed(2)} 미터\n예상 소요 시간: ${timeInMinutes.toStringAsFixed(2)} 분'),
          actions: [
            TextButton(
              child: Text('대여하기'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DestRiding()), // DestRiding 화면으로 이동
                );
              },
            ),
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  double _calculateDistance(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) {
    const double R = 6371000; // Radius of Earth in meters
    final double dLat = _degToRad(endLat - startLat);
    final double dLng = _degToRad(endLng - startLng);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_degToRad(startLat)) * cos(_degToRad(endLat)) *
                sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
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
          "목적지 선택",
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
              onPressed: _calculateDistanceAndTime,
              child: Text("거리 계산하기"),
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
