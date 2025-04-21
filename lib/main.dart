import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdftranslate/screen/fullpdf.dart'; // Make sure this contains TranslationModeScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Translate PDF',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController(); // Email
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _handleAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      print('🔐 Authentication started...');

      if (_isLogin) {
        print('➡️ Attempting login for: ${_usernameController.text}');
        UserCredential user = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print(user.user?.email);
        print('✅ Login successful');
      } else {
        print('👤 Attempting signup for: ${_usernameController.text}');

        if (_passwordController.text != _confirmPasswordController.text) {
          print('❌ Passwords do not match');
          throw Exception('Passwords do not match.');
        }

        final userCredential = await auth.createUserWithEmailAndPassword(
          email: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );

        print('✅ Signup successful. UID: ${userCredential.user?.uid}');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'fullName': _fullNameController.text.trim(),
          'email': _usernameController.text.trim(),
        });

        print('📥 User data saved to Firestore');
      }

      // Navigate to Translation Mode screen
      print('📦 Navigating to TranslationModeScreen...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TranslationModeScreen()),
      );
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('📋 StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Text(
                _isLogin ? 'Login to Translate PDF' : 'Create an Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _isLogin
                    ? 'Enter your credentials to access your account'
                    : 'Fill in your details to create an account',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (!_isLogin) ...[
                _buildTextField('Full Name', 'Enter your full name', controller: _fullNameController),
                const SizedBox(height: 20),
              ],
              _buildTextField('Email', 'Enter your email', controller: _usernameController),
              const SizedBox(height: 20),
              _buildTextField('Password', 'Enter your password', isPassword: true, controller: _passwordController),
              if (!_isLogin) ...[
                const SizedBox(height: 20),
                _buildTextField('Confirm Password', 'Re-enter your password', isPassword: true, controller: _confirmPasswordController),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColorDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isLogin ? 'Login' : 'Sign Up',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin
                        ? 'Don\'t have an account? '
                        : 'Already have an account? ',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: _toggleAuthMode,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isLogin ? 'Sign up' : 'Login',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      {bool isPassword = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
