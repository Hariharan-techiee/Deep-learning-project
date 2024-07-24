// signup_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mini/login_page.dart';
import 'package:mini/camera_page.dart';

// Import the login page

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference().child('signin');
  String _errorMessage = ''; // New variable for storing error messages

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Road Safe Navigator', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/sign.gif',
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
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
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _errorMessage = ''; // Clear previous error messages
                  });

                  // Validate the email format
                  if (!_isValidEmail(_emailController.text)) {
                    setState(() {
                      _errorMessage = 'Invalid email format';
                    });
                    return;
                  }

                  // Validate password and confirm password
                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    setState(() {
                      _errorMessage = 'Passwords do not match';
                    });
                    return;
                  }

                  try {
                    UserCredential userCredential =
                        await _auth.createUserWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );

                    // Save user information to Firebase Database
                    _saveUserInfo(userCredential.user?.uid);

                    // Registration successful, you can navigate to the next page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CameraPage()),
                    );
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'weak-password') {
                      setState(() {
                        _errorMessage =
                            'The password provided is too weak less than 6 character.';
                      });
                    } else if (e.code == 'email-already-in-use') {
                      setState(() {
                        _errorMessage =
                            'The account already exists for that email.';
                      });
                    } else {
                      setState(() {
                        _errorMessage = 'An error occurred. Please try again.';
                      });
                    }
                  } catch (e) {
                    setState(() {
                      _errorMessage = '$e';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  onPrimary: Colors.white,
                ),
                child: Text('Sign Up'),
              ),
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                LoginPage()), // Navigate to login page
                      );
                    },
                    child: Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to validate the email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }

  // Function to save user information to Firebase Database
  void _saveUserInfo(String? userId) {
    if (userId != null) {
      DatabaseReference userRef = _databaseReference.child(userId);
      print('Database Reference Path: ${userRef.path}');

      userRef.set({
        'email': _emailController.text,
        'signup_time': DateTime.now().toUtc().toString(),
        // Add more details as needed
      });
    }
  }
}
