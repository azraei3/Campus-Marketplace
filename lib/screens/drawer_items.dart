import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DrawerItems extends StatelessWidget {
  const DrawerItems({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            InkWell(
              onTap: () async{
                if(context.mounted){
                  context.go('/profile');
                }
                Navigator.pop(context);
              },
              child: SizedBox(
                height: 110,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.secondary),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? 'Unknown User',
                                  style: const TextStyle(fontWeight: FontWeight.bold)
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios)
                    ],
                  ),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Sell an Item'),
              onTap: () {
                Navigator.pop(context);
                context.push('/listings/create');
              },
            ),

            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('My Listings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/my-listings');
              },
            ),

            ListTile(
              leading: const Icon(Icons.outbox_outlined),
              title: const Text('My Requests'),
              onTap: () {
                Navigator.pop(context);
                context.push('/my-requests');
              },
            ),

            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Incoming Requests'),
              onTap: () {
                Navigator.pop(context);
                context.push('/incoming-requests');
              },
            ),

            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Chats'),
              onTap: () {
                Navigator.pop(context);
                context.push('/chats');
              },
            ),

            ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: const Text('Saved Items'),
              onTap: () {
                Navigator.pop(context);
                context.push('/saved');
              },
            ),

            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Dashboard & Reports'),
              onTap: () {
                Navigator.pop(context);
                context.push('/dashboard');
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded),
              title: const Text('Your Listing'),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted){
                  context.go('/login');
                }
              }
            ),
          ]
        );
  }
}
