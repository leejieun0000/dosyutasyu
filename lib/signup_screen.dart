import 'package:firebase_auth/firebase_auth.dart';
import 'package:dosyutasyu/login_screen.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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
      appBar: AppBar(
        leading: CloseButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
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
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email:
                      _emailInputText.text.toLowerCase().trim(), // 가입 이메일
                      password: _passInputText.text.trim(), // 비밀번호
                    );
                    print('success registered');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  } on FirebaseAuthException catch (e) {
                    print('an error occured $e');
                  }
                },
                child: Text('이메일 회원가입'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}