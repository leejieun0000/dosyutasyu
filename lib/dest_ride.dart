import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
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
  final int availableBikes;

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

class DestRide extends StatefulWidget {
  const DestRide({Key? key});

  @override
  _DestRideState createState() => _DestRideState();
}

class _DestRideState extends State<DestRide> {
  late GoogleMapController mapController;
  final Location location = Location();
  List<BikeStation> bikeStations = [];

  // 기본 카메라 위치
  CameraPosition currentPosition = CameraPosition(
    target: LatLng(36.368549, 127.343738),
    zoom: 14,
  );

  bool isLoading = true;
  Set<Marker> markers = {};
  LatLng? _selectedStation1;
  LatLng? _selectedStation2;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 현재 위치를 얻는 함수 호출
    fetchBikeStations();
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

    // Draw a circle for the marker background
    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      markerSize / 2.0,
      paint,
    );

    // Draw the bike icon (optional)
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

    // Draw the available bikes count
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

  void _onMarkerTapped(LatLng position) {
    setState(() {
      if (_selectedStation1 == null) {
        _selectedStation1 = position;
      } else if (_selectedStation2 == null) {
        _selectedStation2 = position;
        _calculateDistance();
      } else {
        _selectedStation1 = position;
        _selectedStation2 = null;
      }
    });
  }

  void _calculateDistance() {
    if (_selectedStation1 != null && _selectedStation2 != null) {
      final double distanceInMeters = _computeDistanceBetween(_selectedStation1!, _selectedStation2!);
      final double distanceInKilometers = distanceInMeters / 1000;
      final double averageSpeedInKmH = 15; // 평균 시속 15km/h
      final double timeInHours = distanceInKilometers / averageSpeedInKmH;
      final double timeInMinutes = timeInHours * 60;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('두 정류소 간의 거리'),
            content: Text('거리: ${distanceInMeters.toStringAsFixed(2)} 미터\n예상 소요 시간: ${timeInMinutes.toStringAsFixed(2)} 분'),
            actions: [
              TextButton(
                child: Text('대여하기'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // 대여하기 버튼이 눌렸을 때 수행할 작업을 여기에 추가
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
  }

  double _computeDistanceBetween(LatLng start, LatLng end) {
    final double distanceInMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return distanceInMeters;
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
          onTap: () {
            _onMarkerTapped(LatLng(station.latitude, station.longitude));
          },
        ),
      );
    }
    setState(() {});
  }

  // 현재 위치를 얻는 함수
  void _getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // 위치 서비스 활성화 확인
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // 위치 권한 확인
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // 현재 위치 얻기
    _locationData = await location.getLocation();
    setState(() {
      currentPosition = CameraPosition(
        target: LatLng(_locationData.latitude!, _locationData.longitude!),
        zoom: 14,
      );
      isLoading = false;
    });

    // 지도의 카메라 위치를 현재 위치로 이동
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(currentPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context){
            return RotatedBox(quarterTurns: 0,child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),);
          },
        ),
        title: Text("목적지 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFFBF30),
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: currentPosition,
            onMapCreated: (controller) => mapController = controller,
            markers: markers,
          ),
        ],
      ),
    );
  }
}
