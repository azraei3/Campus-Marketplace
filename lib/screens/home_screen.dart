import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'drawer_items.dart';

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
          icon: const Icon(Icons.notifications_rounded),
          onPressed: () {

          }
        ),
       ],
      ),
      drawer: Drawer(
        // backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const DrawerItems(),
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
              user?.displayName ?? 'Unknown User',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          ]
        )
      )
    );
  }
}