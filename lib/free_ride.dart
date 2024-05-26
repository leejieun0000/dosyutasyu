import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'home_screen.dart';

class FreeRide extends StatefulWidget {
  const FreeRide({Key? key}) : super(key: key);

  @override
  _FreeRideState createState() => _FreeRideState();
}

class _FreeRideState extends State<FreeRide> {
  late GoogleMapController mapController;
  final Location location = Location();

  // 기본 카메라 위치
  CameraPosition currentPosition = CameraPosition(
    target: LatLng(36.368549, 127.343738),
    zoom: 14,
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

  void _showReturnCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("반납완료!"),
          content: Text("반납이 완료되었습니다."),
          actions: <Widget>[
            TextButton(
              child: Text("확인"),
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                ); // HomeScreen으로 이동
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // Stack 위젯을 사용하여 지도와 버튼 겹치기
        children: [
          GoogleMap( // Google Maps 위젯
            initialCameraPosition: currentPosition,
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            zoomControlsEnabled: false,
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
                  onPressed: _showReturnCompleteDialog,
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white
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
    );
  }
}
