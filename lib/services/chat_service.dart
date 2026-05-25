import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';
import '../models/listing_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<ChatModel> get _chats => _db
      .collection('chats')
      .withConverter<ChatModel>(
        fromFirestore: ChatModel.fromFirestore,
        toFirestore: (ChatModel c, _) => c.toFirestore(),
      );

  CollectionReference<MessageModel> _messages(String chatId) => _db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .withConverter<MessageModel>(
        fromFirestore: MessageModel.fromFirestore,
        toFirestore: (MessageModel m, _) => m.toFirestore(),
      );

  String _composeChatId({
    required String buyerId,
    required String sellerId,
    required String listingId,
  }) {
    final pair = [buyerId, sellerId]..sort();
    return '${pair[0]}_${pair[1]}_$listingId';
  }

  Future<String> getOrCreateChatForListing(ListingModel listing) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to start a chat.');
    }
    if (listing.sellerId == user.uid) {
      throw Exception('You cannot chat with yourself about your own listing.');
    }

    final chatId = _composeChatId(
      buyerId: user.uid,
      sellerId: listing.sellerId,
      listingId: listing.listingId,
    );

    final DocumentReference<ChatModel> ref = _chats.doc(chatId);
    final snap = await ref.get();
    if (snap.exists) return chatId;

    final chat = ChatModel(
      chatId: chatId,
      listingId: listing.listingId,
      listingTitle: listing.title,
      listingImage: listing.imageUrl,
      participants: [user.uid, listing.sellerId],
      buyerId: user.uid,
      sellerId: listing.sellerId,
      lastMessage: '',
    );
    await ref.set(chat);
    return chatId;
  }

  Stream<List<ChatModel>> streamMyChats() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<List<ChatModel>>.value(<ChatModel>[]);
    }
    return _chats
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) {
        final aTime =
            a.lastMessageAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastMessageAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<ChatModel?> streamChat(String chatId) {
    return _chats.doc(chatId).snapshots().map((s) => s.data());
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _messages(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to send messages.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 1000) {
      throw Exception('Message must be under 1000 characters.');
    }

    final messageRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      messageId: messageRef.id,
      senderId: user.uid,
      senderName: user.displayName ?? 'Unknown',
      text: trimmed,
    );

    final batch = _db.batch();
    batch.set(messageRef, message.toFirestore());
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
