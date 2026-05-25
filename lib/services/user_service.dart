import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<UserModel> get _collection => _db
      .collection('users')
      .withConverter<UserModel>(
        fromFirestore: UserModel.fromFirestore,
        toFirestore: (UserModel u, _) => u.toFirestore(),
      );

  Future<UserModel?> getUser(String uid) async {
    final snap = await _collection.doc(uid).get();
    return snap.data();
  }

  Stream<UserModel?> streamUser(String uid) {
    return _collection.doc(uid).snapshots().map((s) => s.data());
  }

  Future<bool> currentUserIsVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.emailVerified) return true;
    final doc = await _collection.doc(user.uid).get();
    return doc.data()?.isVerified ?? false;
  }
}
