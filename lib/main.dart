import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'scanner/scanner.dart'; // QR 코드 스캔 화면을 import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent, // Appbar 배경 투명
          titleTextStyle: TextStyle(
            color: Colors.blue, // 파란색 글자
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;
  final Location location = Location();

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
      appBar: AppBar(
        title: Text(
          "도슈타슈",
          style: TextStyle(
            color: Colors.blue, // 글자 색 파란색으로 설정
            fontWeight: FontWeight.bold, // 굵은 글꼴로 설정
          ),
        ),
        centerTitle: true, // 제목을 가운데 정렬
        backgroundColor: Colors.transparent, // 앱바 배경을 투명하게 설정
        leading: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/images/home_menu.png'), // 이미지로 버튼 채우기
                  backgroundColor: Color(0xFFBF30),
                ),
              ),
            );
          },
        ),

      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: currentPosition,
              markers: markers,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // 버튼을 화면 너비에 맞게 설정
              child: ElevatedButton(
                onPressed: () {
                  _showRentReturnPopup(context, 'assets/images/rent1.png');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16), // 버튼 높이 설정
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: Color(0xFFBF30), // 버튼 배경색 노란색으로 설정
                ),
                child: Text("QR 코드 스캔"),
              ),
            ),
          ),
        ],
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: _moveCameraToCurrentPosition,
        tooltip: '현재 위치로 이동',
        child: const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.endDocked, // 우측 하단에 위치시키기
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
                    backgroundImage: AssetImage('assets/image/rent2.jpg'),
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
