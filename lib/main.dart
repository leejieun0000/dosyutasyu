import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' as math;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

  // 기본 카메라 위치
  CameraPosition currentPosition = CameraPosition(
      target: LatLng(37.555946, 126.972317),
      zoom : 14,
  );

  bool isLoading = true;

  Set<Marker> markers = {};

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

    // 위치 정보의 변화를 실시간으로 감지하기 위한 리스너 설정
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        currentPosition = CameraPosition(
          target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
          zoom: 14,
        );

        isLoading = false;

        // 마커 추가
        markers.add(
          Marker(
            markerId: MarkerId("currentLocation"),
            position: LatLng(currentLocation.latitude!, currentLocation.longitude!),
            infoWindow: InfoWindow(
              title: "현재 위치",
            ),
            // 사용자가 보고 있는 방향을 나타내는 화살표 아이콘 추가
            // 여기서는 임시로 화살표 아이콘 대신 기본 아이콘을 회전시키는 방법을 사용
            rotation: currentLocation.heading!, // 방향(헤딩)에 따라 마커 회전
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

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
           title: Text("도슈타슈"),
     ),
       body: isLoading
           ? Center(child: CircularProgressIndicator())
           : Container(
               child: GoogleMap(
                 initialCameraPosition: currentPosition,
                 markers: markers,
                 onMapCreated: (GoogleMapController controller) {
                   mapController = controller;
                 },
               ),
           ),
       floatingActionButton: FloatingActionButton(
         onPressed: _moveCameraToCurrentPosition,
         tooltip: '현재 위치로 이동',
         child: const Icon(Icons.my_location),
       ),
     );
  }
}
