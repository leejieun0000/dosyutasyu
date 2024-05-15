import 'package:flutter/material.dart';

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
          builder: (BuildContext context){
            return RotatedBox(quarterTurns: 0,child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),);
          },
        ),
        title: Text("대여하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFFBF30),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement 자유 이용 onPressed action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFBF30), // 버튼 배경색 노란색
                ),
                child: Text("자유 이용", style: TextStyle(color: Colors.black)), // 글자색 검은색
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement 목적지 선택 onPressed action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFBF30), // 버튼 배경색 노란색
                ),
                child: Text("목적지 선택", style: TextStyle(color: Colors.black)), // 글자색 검은색
              ),
            ],
          ),
        ),
      ),
    );
  }
}
