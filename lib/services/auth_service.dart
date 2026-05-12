import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

//login Future async function
  Future<User?> logIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );


      User? user = userCredential.user;

      if(user != null && !user.emailVerified){
        await _auth.signOut();
        throw Exception('Please verify your email before loggin in.');
      }

      return user;
    }
    on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid email or password.');
      } else {
        throw Exception(e.message ?? 'An unknown error occurred.');
      }
    }
  }

  Future<User?> register({required String email, required String password, required String name}) async {
    try {
      // 1. Validate University Email
      if (!email.toLowerCase().endsWith('utm.my')){
        throw Exception('Please use a valid university email to register.');
      }

      // 2. Create the account in Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //Send the verification email
      await userCredential.user?.sendEmailVerification();
      
      //store profile in firestore
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': userCredential.user!.uid,
        });
      
      await FirebaseAuth.instance.signOut();
    }
    on FirebaseAuthException catch (e) {
      if(e.code == 'weak-password'){
        throw Exception('The password provided is too weak.');
      } else if(e.code == 'email-already-in-use'){
        throw Exception('An account already exists for that email.');
      } else {
        throw Exception(e.message ?? 'An unknown error occurred.');
      }
    }
    catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

//logout Future function
  Future<void> signOut() => FirebaseAuth.instance.signOut();
}