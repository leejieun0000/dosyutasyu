import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:dosyutasyu/login_screen.dart';

// 기존의 main(지도 나오는 거) 확인하고 싶으면 2가지만 변경하면 됨. 주석 확인해봐

// 기존 1
// void main() {
//   runApp(const MyApp());
// }

// 파베 변화1
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key});
  //const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home : LoginScreen(), //파베 변화 2
      //home: const MyHomePage(), //기존 2
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
    );
  }
}