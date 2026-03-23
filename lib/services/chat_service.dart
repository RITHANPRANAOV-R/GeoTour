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

    final chatData = {
      'participants': participants,
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    
    // Update or create chat header
    batch.set(_firestore.collection('chats').doc(chatId), chatData, SetOptions(merge: true));
    
    // Add message
    batch.set(_firestore.collection('chats').doc(chatId).collection('messages').doc(), messageData);

    await batch.commit();
  }

  Stream<QuerySnapshot> getConversationsStream(String userId) {
    // Note: orderBy requires a composite index with array-contains.
    // We'll use a simpler query if the index isn't ready.
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }
}
