import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isVerified;
  final double averageRating;
  final int totalRatings;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.isVerified = false,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.createdAt,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserModel(
      uid: snapshot.id,
      name: data?['name'] ?? 'Unknown',
      email: data?['email'] ?? '',
      isVerified: data?['isVerified'] == true,
      averageRating: (data?['averageRating'] is num)
          ? (data!['averageRating'] as num).toDouble()
          : 0.0,
      totalRatings: (data?['totalRatings'] is num)
          ? (data!['totalRatings'] as num).toInt()
          : 0,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isVerified': isVerified,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}