import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'scanner/scanner.dart'; // QR 코드 스캔 화면을 import
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;
  final Location location = Location();
  List<BikeStation> bikeStations = [];

  // 기본 카메라 위치
  CameraPosition currentPosition = CameraPosition(
    target: LatLng(37.555946, 126.972317),
    zoom: 14,
  );

  bool isLoading = true;
  Set<Marker> markers = {};
  bool _isPopupShown = false; // 팝업이 떠있는지 여부를 나타내는 변수
  bool _isRentReturnPopupShown = false;

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
      final jsonData = json.decode(response.body);
      final results = jsonData['results'];
      List<BikeStation> stations = [];

      for (var result in results) {
        stations.add(BikeStation.fromJson(result));
      }

      setState(() {
        bikeStations = stations;
      });
    } else {
      throw Exception('Failed to load bike stations');
    }
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
        if (!_isPopupShown) {
          _showImagePopup();
          _isPopupShown = true; // 팝업이 뜬 상태로 변경
        }
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

  void _showImagePopup() async {
    if (!_isPopupShown) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 12), // 사진과 버튼 사이 간격 조정
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Image.asset('assets/images/popup1.png'), // a.png 이미지를 나타내는 위젯
                ),
                SizedBox(height: 16), // 사진과 버튼 사이 추가 간격
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      child: const Text('7일간 보지 않기'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _isPopupShown = true; // 팝업이 닫힌 상태로 변경
                      },
                    ),
                    SizedBox(width: 16),
                    TextButton(
                      child: const Text('확인'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _isPopupShown = true; // 팝업이 닫힌 상태로 변경
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _showRentReturnPopup(BuildContext context, String imagePath, {String title = '대여/반납 안내'}) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color : Colors.orange,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Image.asset(imagePath),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: const Text('닫기'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  SizedBox(width: 16),
                  TextButton(
                    child: const Text('다음'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      if (imagePath == 'assets/images/rent1.png') {
        await _showRentReturnPopup(context, 'assets/images/rent2.png');
      } else if (imagePath == 'assets/images/rent2.png') {
        await _showRentReturnPopup(context, 'assets/images/rent3.png');
      } else if (imagePath == 'assets/images/rent3.png') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Scanner()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // Stack 위젯을 사용하여 지도와 버튼 겹치기
        children: [
          GoogleMap( // Google Maps 위젯
            initialCameraPosition: currentPosition,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
        markers: bikeStations
            .map((station) => Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          station.name,
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Available Bikes: ${station.availableBikes}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ))
            .toSet(),
            zoomControlsEnabled: true,
          ),
          Positioned( // 현재 위치 버튼 위치 변경
            bottom: 80.0, // 하단 여백
            right: 15.0,  // 오른쪽 여백 - 이 값을 조절하여 왼쪽으로 이동
            child: FloatingActionButton(
              onPressed: _moveCameraToCurrentPosition,
              tooltip: '현재 위치로 이동',
              child: const Icon(Icons.my_location),
            ),
          ),

          Align( // 버튼을 화면 아래에 배치
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showRentReturnPopup(context, 'assets/images/rent1.png');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white
                  ),
                  child: Text("대여하기"),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              title: Image.asset(
                'assets/images/doshutashulogo.png', // 이미지 경로
                height: 40, // 이미지 높이 (선택 사항)
                fit: BoxFit.contain, // 이미지를 AppBar 높이에 맞춰 조절
              ),
              centerTitle: true, // 제목을 가운데 정렬
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 4,
              leading: Builder(
                builder: (context) {
                  return GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: AssetImage('assets/images/menu_yellow.png'), // 이미지로 버튼 채우기
                        backgroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/people2.png'),
                    radius: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '김민성',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('홈'),
              onTap: () {
                // 홈 화면으로 이동하는 코드 추가
                Navigator.pop(context); // 드로어 닫기
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('설정'),
              onTap: () {
                // 설정 화면으로 이동하는 코드 추가
                Navigator.pop(context); // 드로어 닫기
              },
            ),
            // 추가 메뉴 항목을 여기에 추가
          ],
        ),
      ),

    );
  }
}