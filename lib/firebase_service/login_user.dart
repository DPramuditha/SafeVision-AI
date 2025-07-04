import 'package:firebase_auth/firebase_auth.dart';

class LoginUser {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("✅User registered successfully: ${userCredential.user?.uid}");
      print("User registered: ${userCredential.user?.email}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'weak-password') {
        print("❌The password provided is too weak.");
        throw Exception("The password provided is too weak.");
      } else if (e.code == 'email-already-in-use') {
        print("❌The account already exists for that email.");
        throw Exception("The account already exists for that email.");
      } else if (e.code == 'invalid-email') {
        print("❌The email address is not valid.");
        throw Exception("The email address is not valid.");
      } else {
        print("❌Error registering user: ${e.message}");
        throw Exception("Error registering user: ${e.message}");
      }
    } catch (e) {
      // Handle registration errors
      print("❌Error registering user: $e");
      throw Exception("Error registering user: $e");
    }
  }

  Future<UserCredential?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      print("✅User logged in successfully: ${_auth.currentUser?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        print("❌No user found for that email.");
        throw Exception("No user found for that email.");
      } else if (e.code == 'wrong-password') {
        print("❌Wrong password provided for that user.");
        throw Exception("Wrong password provided for that user.");
      } else if (e.code == 'invalid-email') {
        print("❌The email address is not valid.");
        throw Exception("The email address is not valid.");
      } else {
        print("❌Error logging in user: ${e.message}");
        throw Exception("Error logging in user: ${e.message}");
      }
    } catch (e) {
      // Handle login errors
      print("❌Error logging in user: $e");
      throw Exception("Error logging in user: $e");
    }
  }

  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
      print("✅User logged out successfully");
    } catch (e) {
      // Handle logout errors
      print("❌Error logging out user: $e");
      throw Exception("Error logging out user: $e");
    }
  }
}