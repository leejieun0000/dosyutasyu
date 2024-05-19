import 'package:firebase_auth/firebase_auth.dart';
import 'package:dosyutasyu/home_screen.dart';
import 'package:dosyutasyu/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

//구글 관련 내용은 지우거나 더 설치하기

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _emailInputText = TextEditingController();
  var _passInputText = TextEditingController();

  void dispose() {
    _emailInputText.dispose();
    _passInputText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                controller: _emailInputText,
                decoration: InputDecoration(hintText: 'Email'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                controller: _passInputText,
                obscureText: true,
                decoration: InputDecoration(hintText: 'Password'),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 5),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // 이메일, 비번 중 하나라도 비워있으면 패스
                  if (_emailInputText.text.isEmpty ||
                      _passInputText.text.isEmpty) return;

                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _emailInputText.text.toLowerCase().trim(),
                      password: _passInputText.text.trim(),
                    );
                    print('success login');

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  } on FirebaseAuthException catch (e) {
                    print('an error occured $e');
                  }
                },
                child: Text('이메일 로그인'),
              ),
            ),
            // 구글로 로그인
            // Container(
            //   padding: EdgeInsets.symmetric(vertical: 5),
            //   width: double.infinity,
            //   child:
            //   ElevatedButton(
            //     onPressed: () async {
            //       final _googleSignIn = GoogleSignIn();
            //       final googleAccount = await _googleSignIn.signIn();
            //
            //       if (googleAccount != null) {
            //         final googleAuth = await googleAccount.authentication;
            //
            //         if (googleAuth.accessToken != null &&
            //             googleAuth.idToken != null) {
            //           try {
            //             await FirebaseAuth.instance
            //                 .signInWithCredential(GoogleAuthProvider.credential(
            //               idToken: googleAuth.idToken,
            //               accessToken: googleAuth.accessToken,
            //             ));
            //             print('success registered');
            //             Navigator.push(
            //               context,
            //               MaterialPageRoute(builder: (context) => MyHomePage()),
            //             );
            //           } on FirebaseAuthException catch (e) {
            //             print('an error occured $e');
            //           } catch (e) {
            //             print('an error occured $e');
            //           }
            //         } else
            //           print('an error occured');
            //       } else
            //         print('an error occured');
            //     },
            //     child: Text('구글로 시작하기'),
            //   ),
            // ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                // width: double.infinity,
                child: Text('회원가입 하러가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}