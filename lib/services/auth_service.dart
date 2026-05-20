import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<User?> logIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw AuthException('Please verify your email before logging in.');
      }

      if (user != null && user.emailVerified) {
        await _db.collection('users').doc(user.uid).set(
          {'isVerified': true},
          SetOptions(merge: true),
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authErrorMessage(e));
    }
  }

  Future<User?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (!email.toLowerCase().endsWith('utm.my')) {
        throw AuthException('Please use a valid university email to register.');
      }
      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters.');
      }
      if (name.trim().isEmpty) {
        throw AuthException('Please enter your full name.');
      }

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        final newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
        );

        final docRef = _db
            .collection('users')
            .withConverter(
              fromFirestore: UserModel.fromFirestore,
              toFirestore: (UserModel newUser, options) => newUser.toFirestore(),
            )
            .doc(user.uid);

        await docRef.set(newUser);
        await user.sendEmailVerification();
      }

      await FirebaseAuth.instance.signOut();
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authErrorMessage(e));
    }
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is disabled. Enable it in the Firebase Console under Authentication > Sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return '${e.message ?? 'Authentication failed.'} (code: ${e.code})';
    }
  }
}
