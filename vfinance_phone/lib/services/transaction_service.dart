import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Represents a transaction document from Firestore
class TransactionDoc {
  final String id;
  final String muc;
  final int soTien;
  final DateTime thoiGian;
  final String? ghiChu;
  final String? subCategory;

  TransactionDoc({
    required this.id,
    required this.muc,
    required this.soTien,
    required this.thoiGian,
    this.ghiChu,
    this.subCategory,
  });

  factory TransactionDoc.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data()!;
      return TransactionDoc(
        id: doc.id,
        muc: data['muc'] as String? ?? 'Khác',
        soTien: ((data['soTien'] as num?) ?? 0).toInt(),
        thoiGian: (data['thoiGian'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ghiChu: data['ghiChu'] as String?,
        subCategory: data['subCategory'] as String?,
      );
    } catch (e) {
      debugPrint('[TransactionDoc] Error parsing doc ${doc.id}: $e');
      // Return a safe default instead of crashing
      return TransactionDoc(
        id: doc.id,
        muc: 'Error',
        soTien: 0,
        thoiGian: DateTime.now(),
        ghiChu: 'Error parsing: $e',
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'muc': muc,
      'soTien': soTien,
      'thoiGian': Timestamp.fromDate(thoiGian),
      'ghiChu': ghiChu,
      if (subCategory != null) 'subCategory': subCategory,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Cloud First Transaction Service
/// All data is stored in Firestore - single source of truth
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get reference to user's transactions collection
  CollectionReference<Map<String, dynamic>>? get _transactionsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of all transactions (real-time updates)
  Stream<List<TransactionDoc>> get transactionsStream {
    final ref = _transactionsRef;
    if (ref == null) {
      debugPrint('[TransactionService] transactionsStream: user not logged in, returning empty stream');
      return Stream.value([]);
    }
    
    debugPrint('[TransactionService] transactionsStream: subscribing to Firestore...');
    return ref
        .orderBy('thoiGian', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('[TransactionService] Received ${snapshot.docs.length} transactions from Firestore');
          return snapshot.docs
              .map((doc) => TransactionDoc.fromFirestore(doc))
              .toList();
        });
  }

  /// Add a new transaction
  Future<void> add({
    required String muc,
    required int soTien,
    required DateTime thoiGian,
    String? ghiChu,
    String? subCategory,
  }) async {
    final ref = _transactionsRef;
    if (ref == null) {
      debugPrint('[TransactionService] Cannot add transaction: user not logged in');
      return;
    }

    debugPrint('[TransactionService] Adding transaction: muc=$muc, soTien=$soTien, subCategory=$subCategory');
    try {
      await ref.add({
        'muc': muc,
        'soTien': soTien,
        'thoiGian': Timestamp.fromDate(thoiGian),
        'ghiChu': ghiChu,
        if (subCategory != null) 'subCategory': subCategory,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[TransactionService] Transaction added successfully!');
    } catch (e) {
      debugPrint('[TransactionService] Error adding transaction: $e');
    }
  }

  /// Update an existing transaction
  Future<void> update(String docId, {
    String? muc,
    int? soTien,
    DateTime? thoiGian,
    String? ghiChu,
  }) async {
    final ref = _transactionsRef;
    if (ref == null) return;

    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (muc != null) updateData['muc'] = muc;
    if (soTien != null) updateData['soTien'] = soTien;
    if (thoiGian != null) updateData['thoiGian'] = Timestamp.fromDate(thoiGian);
    if (ghiChu != null) updateData['ghiChu'] = ghiChu;

    await ref.doc(docId).update(updateData);
  }

  /// Delete a transaction
  Future<void> delete(String docId) async {
    final ref = _transactionsRef;
    if (ref == null) return;

    await ref.doc(docId).delete();
  }

  /// Delete all transactions for today
  Future<void> deleteAllForDay(DateTime date) async {
    final ref = _transactionsRef;
    if (ref == null) return;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await ref
        .where('thoiGian', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('thoiGian', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Get transactions for a specific day
  Stream<List<TransactionDoc>> transactionsForDay(DateTime date) {
    final ref = _transactionsRef;
    if (ref == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return ref
        .where('thoiGian', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('thoiGian', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('thoiGian', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionDoc.fromFirestore(doc))
            .toList());
  }

  /// Get transactions for a specific month
  Stream<List<TransactionDoc>> transactionsForMonth(int year, int month) {
    final ref = _transactionsRef;
    if (ref == null) return Stream.value([]);

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    return ref
        .where('thoiGian', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('thoiGian', isLessThan: Timestamp.fromDate(endOfMonth))
        .orderBy('thoiGian', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionDoc.fromFirestore(doc))
            .toList());
  }
}

/// Global instance
final transactionService = TransactionService();
