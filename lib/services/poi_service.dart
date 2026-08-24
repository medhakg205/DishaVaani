import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poi.dart';

//This creates a reference (like a bookmark/pointer) to the pois collection in Firestore
class PoiService {
  final CollectionReference _poisRef =
      FirebaseFirestore.instance.collection('pois');

  //this function will eventually give you back a list of Poi objects,
  Future<List<Poi>> fetchAllPois() async {

    //asks Firestore for every document in the pois collection, and pauses this function until the response comes back.
    final snapshot = await _poisRef.get();

    //takes every raw document in the snapshot and runs it through your fromFirestore translator, converting each one into a proper Poi object, then collects them all into a clean List<Poi> — which is what finally gets returned to whoever called fetchAllPois()
    return snapshot.docs
        .map((doc) =>
            Poi.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
}