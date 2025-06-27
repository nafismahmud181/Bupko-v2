import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- FAVORITES LOGIC ---

  Future<void> addFavorite(Map<String, dynamic> bookData) async {
    final user = currentUser;
    if (user == null) return;
    final favRef = _firestore.collection('users').doc(user.uid).collection('favorites').doc(bookData['id']);
    await favRef.set(bookData);
  }

  Future<void> removeFavorite(String bookId) async {
    final user = currentUser;
    if (user == null) return;
    final favRef = _firestore.collection('users').doc(user.uid).collection('favorites').doc(bookId);
    await favRef.delete();
  }

  Future<bool> isFavorite(String bookId) async {
    final user = currentUser;
    if (user == null) return false;
    final favRef = _firestore.collection('users').doc(user.uid).collection('favorites').doc(bookId);
    final doc = await favRef.get();
    return doc.exists;
  }

  Stream<List<String>> favoriteBookIdsStream() {
    final user = currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user.uid).collection('favorites').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.id).toList(),
    );
  }
} 