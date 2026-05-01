import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context){
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
       title: const Text('Home'),
       actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () async{
            if(context.mounted){
              context.go('/profile');
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const ProfileScreen()),
              // );
            }
          }
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted){
              context.go('/login');
              // Navigator.pushReplacement(
              //   context, 
              //   MaterialPageRoute(builder: (context) => const LoginScreen()),
              // );
            }
          }
        )
       ] 
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome Back!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              user?.email ?? 'Unkown User',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          ]
        )
      )
    );
  }
}