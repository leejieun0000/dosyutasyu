import 'package:flutter/material.dart';
import 'package:dosyutasyu/free_ride.dart';
import 'package:dosyutasyu/dest_ride.dart';

class FoundScreen extends StatefulWidget {
  final String value;
  final Function() screenClose;
  const FoundScreen({Key? key, required this.value, required this.screenClose}) : super(key: key);

  @override
  State<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends State<FoundScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return RotatedBox(
              quarterTurns: 0,
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: Colors.black), // 글자색 검은색
                onPressed: () => Navigator.pop(context, false),
              ),
            );
          },
        ),
        title: Center(
          child: Text(
            "대여하기",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black), // 글자색 검은색
          ),
        ),
        backgroundColor: Color(0xFFFFD700), // 배경색 (노란색)
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FreeRide(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFD700), // 버튼 배경색 노란색
                  minimumSize: Size(double.infinity, 60), // 버튼 크기 가로로 길게
                  padding: EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: Icon(Icons.directions_bike, color: Colors.black),
                label: Text(
                  "자유 이용",
                  style: TextStyle(color: Colors.black, fontSize: 18), // 글자색 검은색
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DestinationRide()), // Navigate to DestRide
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFD700), // 버튼 배경색 노란색
                  minimumSize: Size(double.infinity, 60), // 버튼 크기 가로로 길게
                  padding: EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: Icon(Icons.location_on, color: Colors.black),
                label: Text(
                  "목적지 선택",
                  style: TextStyle(color: Colors.black, fontSize: 18), // 글자색 검은색
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
