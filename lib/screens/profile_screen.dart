import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'widgets/verified_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in.')));
    }

    final UserService userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: StreamBuilder<UserModel?>(
        stream: userService.streamUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final UserModel? me = snapshot.data;
          final bool verified = me?.isVerified ?? user.emailVerified;
          final String displayName =
              me?.name ?? user.displayName ?? 'No Name Provided';
          final String displayEmail = me?.email ?? user.email ?? 'No Email';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const VerifiedBadge(size: 20),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  displayEmail,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              if (me != null && me.totalRatings > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '★ ${me.averageRating.toStringAsFixed(1)} · ${me.totalRatings} reviews',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Saved Items'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push('/saved'),
              ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('My Listings'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push('/my-listings'),
              ),
              ListTile(
                leading: const Icon(Icons.outbox_outlined),
                title: const Text('My Requests'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push('/my-requests'),
              ),
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('Incoming Requests'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push('/incoming-requests'),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chats'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push('/chats'),
              ),
            ],
          );
        },
      ),
    );
  }
}
