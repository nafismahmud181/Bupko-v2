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

  // --- FOLLOW AUTHOR LOGIC ---
  Future<void> followAuthor(String authorId) async {
    final user = currentUser;
    if (user == null) return;
    final userFollowRef = _firestore.collection('users').doc(user.uid).collection('followed_authors').doc(authorId);
    final authorRef = _firestore.collection('authors').doc(authorId);
    await _firestore.runTransaction((transaction) async {
      // READ FIRST
      final authorSnap = await transaction.get(authorRef);
      // THEN WRITE
      transaction.set(userFollowRef, {'followedAt': FieldValue.serverTimestamp()});
      final currentCount = (authorSnap.data()?['followersCount'] ?? 0) as int;
      transaction.set(authorRef, {'followersCount': currentCount + 1}, SetOptions(merge: true));
    });
  }

  Future<void> unfollowAuthor(String authorId) async {
    final user = currentUser;
    if (user == null) return;
    final userFollowRef = _firestore.collection('users').doc(user.uid).collection('followed_authors').doc(authorId);
    final authorRef = _firestore.collection('authors').doc(authorId);
    await _firestore.runTransaction((transaction) async {
      // READ FIRST
      final authorSnap = await transaction.get(authorRef);
      // THEN WRITE
      transaction.delete(userFollowRef);
      final currentCount = (authorSnap.data()?['followersCount'] ?? 1) as int;
      final newCount = (currentCount > 0) ? currentCount - 1 : 0;
      transaction.set(authorRef, {'followersCount': newCount}, SetOptions(merge: true));
    });
  }

  Future<bool> isFollowingAuthor(String authorId) async {
    final user = currentUser;
    if (user == null) return false;
    final userFollowRef = _firestore.collection('users').doc(user.uid).collection('followed_authors').doc(authorId);
    final doc = await userFollowRef.get();
    return doc.exists;
  }

  Stream<int> getFollowersCountStream(String authorId) {
    final authorRef = _firestore.collection('authors').doc(authorId);
    return authorRef.snapshots().map((snap) => (snap.data()?['followersCount'] ?? 0) as int);
  }
} 