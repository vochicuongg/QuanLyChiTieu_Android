import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Database service for real-time Firestore sync
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _transactionsRef {
    if (_uid == null) return null;
    return _firestore.collection('users').doc(_uid).collection('transactions');
  }

  // =================== WRITE: Direct push ===================
  
  /// Add a new transaction (expense or income)
  Future<void> addTransaction(Map<String, dynamic> data) async {
    final ref = _transactionsRef;
    if (ref == null) return;
    await ref.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing transaction
  Future<void> updateTransaction(String docId, Map<String, dynamic> data) async {
    final ref = _transactionsRef;
    if (ref == null) return;
    await ref.doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String docId) async {
    final ref = _transactionsRef;
    if (ref == null) return;
    await ref.doc(docId).delete();
  }

  // =================== READ: Stream for real-time updates ===================
  
  /// Stream of all transactions for the current user
  /// Automatically updates UI when data changes (add/edit/delete)
  Stream<QuerySnapshot<Map<String, dynamic>>> get transactionsStream {
    final ref = _transactionsRef;
    if (ref == null) {
      return const Stream.empty();
    }
    return ref.orderBy('thoiGian', descending: true).snapshots();
  }

  /// Stream of transactions filtered by date
  Stream<QuerySnapshot<Map<String, dynamic>>> transactionsByDate(DateTime date) {
    final ref = _transactionsRef;
    if (ref == null) {
      return const Stream.empty();
    }
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return ref
        .where('thoiGian', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('thoiGian', isLessThan: endOfDay.toIso8601String())
        .snapshots();
  }

  /// Stream of transactions for current month
  Stream<QuerySnapshot<Map<String, dynamic>>> get currentMonthTransactions {
    final ref = _transactionsRef;
    if (ref == null) {
      return const Stream.empty();
    }
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return ref
        .where('thoiGian', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('thoiGian', isLessThan: endOfMonth.toIso8601String())
        .snapshots();
  }

  // =================== MIGRATION: One-time local data push ===================
  
  /// Migrate old local data to Firestore (call once after login)
  Future<void> migrateLocalData(List<Map<String, dynamic>> localTransactions) async {
    final ref = _transactionsRef;
    if (ref == null) return;
    
    final batch = _firestore.batch();
    for (final transaction in localTransactions) {
      batch.set(ref.doc(), {
        ...transaction,
        'migratedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

// Global instance
final databaseService = DatabaseService();
