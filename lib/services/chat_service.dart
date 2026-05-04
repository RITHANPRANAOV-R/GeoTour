import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required List<String> participants,
  }) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();

    // Update or create chat header with arrayUnion to prevent removing existing participants
    batch.set(
      _firestore.collection('chats').doc(chatId),
      {
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    
    batch.update(
      _firestore.collection('chats').doc(chatId),
      {
        'participants': FieldValue.arrayUnion(participants),
      }
    );

    // Add message
    batch.set(
      _firestore.collection('chats').doc(chatId).collection('messages').doc(),
      messageData,
    );

    // Update unread counts for other participants
    final Map<String, dynamic> unreadUpdates = {};
    for (String id in participants) {
      if (id != senderId) {
        unreadUpdates['unreadCounts.$id'] = FieldValue.increment(1);
      }
    }

    batch.set(
      _firestore.collection('chats').doc(chatId),
      unreadUpdates,
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 0,
    });
  }

  Stream<QuerySnapshot> getConversationsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }
}
