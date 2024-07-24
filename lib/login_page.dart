// login_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mini/camera_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RoadSafe Navigator',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/log.jpeg',
                height: 300,
                width: 300,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 30),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _errorMessage = null; // Clear previous error messages
                  });

                  // Validate the email format
                  if (!_isValidEmail(_emailController.text)) {
                    setState(() {
                      _errorMessage = 'Invalid email format';
                    });
                    return;
                  }

                  // Validate password length
                  if (!_isValidPassword(_passwordController.text)) {
                    setState(() {
                      _errorMessage =
                          'Password must be at least 6 characters long';
                    });
                    return;
                  }

                  try {
                    await _auth.signInWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );

                    _saveLoginInfo(_emailController.text);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyAppss(),
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found' ||
                        e.code == 'wrong-password') {
                      setState(() {
                        _errorMessage = 'Invalid email or password';
                      });
                    } else {
                      // Handle other FirebaseAuthException cases
                      print('FirebaseAuthException: ${e.code}');
                      setState(() {
                        // ignore: unnecessary_string_interpolations
                        _errorMessage = '${e.code}';
                      });
                    }
                  } catch (e) {
                    // Handle other exceptions
                    setState(() {
                      // ignore: unnecessary_string_interpolations
                      _errorMessage = '$e';
                    });
                    print('Exception: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  onPrimary: Colors.white,
                ),
                child: Text('Login'),
              ),
              SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
                    },
                    child: Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  void _saveLoginInfo(String email) {
    final loginTime = DateTime.now().toUtc().toString();
    _databaseReference.child('login_info').push().set({
      'email': email,
      'login_time': loginTime,
    });
  }
}
