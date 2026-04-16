import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  FirestoreService(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final reference = _firestore.doc(path);
    await reference.set(data, SetOptions(merge: merge));
  }

  Future<void> deleteData({required String path}) async {
    final reference = _firestore.doc(path);
    await reference.delete();
  }

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) {
    Query query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      final result = snapshot.docs
          .map((snapshot) => builder(snapshot.data() as Map<String, dynamic>, snapshot.id))
          .where((value) => value != null)
          .toList();
      if (sort != null) {
        result.sort(sort);
      }
      return result;
    });
  }

  Future<void> batchUpload<T>({
    required String path,
    required List<T> items,
    required Map<String, dynamic> Function(T item) toMap,
    required String Function(T item) getId,
  }) async {
    final batch = _firestore.batch();
    for (final item in items) {
      final docRef = _firestore.collection(path).doc(getId(item));
      batch.set(docRef, toMap(item));
    }
    await batch.commit();
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});
