import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'device_identity.dart';

class SessionService {
  final CollectionReference _sessionsRef = FirebaseFirestore.instance
      .collection('sessions');

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no confusing 0/O/1/I
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> createSession(String initialPoiId) async {
    final myId = await DeviceIdentity.getId();
    final code = _generateCode();

    final sessionDoc = await _sessionsRef.add({
      'code': code,
      'hostId': myId,
      'audioPlayerId': myId,
      'currentPoiId': initialPoiId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await sessionDoc.collection('members').doc(myId).set({
      'joinOrder': 0,
      'inGroup': true,
      'lat': null,
      'long': null,
    });

    return code;
  }

  Future<String> joinSession(String code) async {
    final myId = await DeviceIdentity.getId();

    final query = await _sessionsRef
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No session found with that code.');
    }

    final sessionDoc = query.docs.first;
    final membersRef = sessionDoc.reference.collection('members');

    final existingMembers = await membersRef.get();
    final nextJoinOrder = existingMembers.docs.length;

    await membersRef.doc(myId).set({
      'joinOrder': nextJoinOrder,
      'inGroup': true,
      'lat': null,
      'long': null,
    });

    return sessionDoc.id;
  }

  Future<void> updateMyLocation({
    required String sessionId,
    required double lat,
    required double long,
  }) async {
    final myId = await DeviceIdentity.getId();

    await _sessionsRef.doc(sessionId).collection('members').doc(myId).update({
      'lat': lat,
      'long': long,
    });
  }
}
