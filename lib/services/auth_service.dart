import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Connectivity _connectivity = Connectivity();

  // Check internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  // Stream of connectivity changes
  Stream<List<ConnectivityResult>> getConnectivityStream() {
    return _connectivity.onConnectivityChanged;
  }

  // Email login
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Email signup
  Future<User?> signupWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Google login
  Future<User?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn
          .signIn();

      if (googleSignInAccount == null) {
        return null;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Check if user is logged in
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
