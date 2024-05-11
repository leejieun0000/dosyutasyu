import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';


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
      home: const MyHomePage(),
    );
    }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;
  final Location location = Location();

  CameraPosition currentPosition = CameraPosition(
    // 기본 카메라 위치
      target: LatLng(37.555946, 126.972317),
      zoom : 14,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 현재 위치를 얻는 함수 호출
  }

  // 현재 위치를 얻는 함수
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
    });
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
           title: Text("도슈타슈"),
     ),
       body : Container(
           child: GoogleMap(
             initialCameraPosition: currentPosition,
             onMapCreated: (GoogleMapController controller) {
               mapController = controller;
           }
           )),
     );
  }
}
