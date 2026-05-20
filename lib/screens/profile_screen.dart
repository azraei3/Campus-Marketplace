import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the user's document from Firestore using their UID
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          // Show a loading spinner while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors or missing data
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error loading profile data.'));
          }

          // Extract the data from the document
          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Name',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                Text(
                  userData['name'] ?? 'No Name Provided',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Text(
                  'University Email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                Text(
                  userData['email'] ?? 'No Email',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 175,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey, width: 2.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.favorite_border_rounded, size: 40),
                            const SizedBox(height: 5),
                            const Text('Saved Items', style: TextStyle(fontSize: 20))
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 175,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey, width: 2.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 40),
                            const SizedBox(height: 5),
                            const Text('Inbox', style: TextStyle(fontSize: 20))
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 175,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey, width: 2.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.settings, size: 40),
                            const SizedBox(height: 5),
                            const Text('Settings', style: TextStyle(fontSize: 20))
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 175,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey, width: 2.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.history, size: 40),
                            const SizedBox(height: 5),
                            const Text('Recently Viewed', style: TextStyle(fontSize: 20), overflow: TextOverflow.ellipsis, maxLines: 1,)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                InkWell(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted){
                      context.go('/login');
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 2.0)),
                    child: Column(children: [Text('Logout', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white))],)
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}