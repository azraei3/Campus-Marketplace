import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
  });

  //Converting Firestore 'document' data to UserModel Dart object
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserModel(
      uid: snapshot.id, //uses actual document ID even if 'uid' field is missing in Firestore instead of data?['uid'] 
      name: data?['name'] ?? 'Unknown',
      email: data?['email'] ?? '',
      createdAt: (data?['createdAt'] as Timestamp ).toDate()
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp()
    };
  }
}