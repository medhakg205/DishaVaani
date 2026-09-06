import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monument.dart';

class MonumentService {
  final _collection = FirebaseFirestore.instance.collection('monuments');

  Future<List<Monument>> getAllMonuments() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Monument.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}