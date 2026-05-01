import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      //Check email verified
      if (userCredential.user != null && !userCredential.user!.emailVerified){
        await FirebaseAuth.instance.signOut();
        setState((){
          _errorMessage = 'Please verify your email before logging in. Check your email inbox or spam folder';
          _isLoading = false;
        });
        return;
      }

      print("Login Successful!");
      if(mounted){
        context.go('/');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Firebase recently updated error codes for security to just 'invalid-credential'
        // but we can check for common ones just in case.
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'Invalid email or password.';
        } else {
          _errorMessage = e.message ?? 'An unknown error occurred.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'University Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            
            const SizedBox(height:10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: (){
                  context.go('/forgot-password');
                },
                child: const Text('Forgot Password?'),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            
            _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : ElevatedButton(
                    onPressed: _loginUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 18)),
                  ),
            
            const SizedBox(height: 15),
            
            // Navigation to Register Screen
            TextButton(
              onPressed: () {
                context.go('/register');
              },
              child: const Text("Don't have an account? Sign up here"),
            ),
          ],
        ),
      ),
    );
  }
}