import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  // Latitude : 위도 (처음 지도 켰을 때 어디 뜨게 할거냐)
  // Longitude : 경도
  final CameraPosition position = CameraPosition(target: LatLng(37.555946, 126.972317), zoom : 14);
  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
           title: Text("도슈타슈"),
     ),
       body : Container(
           child: GoogleMap(
               initialCameraPosition: this.position
           )
       ),
     );
  }
}
