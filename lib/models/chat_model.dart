import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final List<String> participants;
  final String buyerId;
  final String sellerId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  ChatModel({
    required this.chatId,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.participants,
    required this.buyerId,
    required this.sellerId,
    required this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
  });

  factory ChatModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return ChatModel(
      chatId: snapshot.id,
      listingId: data?['listingId'] ?? '',
      listingTitle: data?['listingTitle'] ?? '',
      listingImage: data?['listingImage'] ?? '',
      participants: (data?['participants'] as List?)?.cast<String>() ?? <String>[],
      buyerId: data?['buyerId'] ?? '',
      sellerId: data?['sellerId'] ?? '',
      lastMessage: data?['lastMessage'] ?? '',
      lastMessageAt: (data?['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'participants': participants,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String otherParticipant(String currentUid) {
    return participants.firstWhere(
      (p) => p != currentUid,
      orElse: () => '',
    );
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return MessageModel(
      messageId: snapshot.id,
      senderId: data?['senderId'] ?? '',
      senderName: data?['senderName'] ?? 'Unknown',
      text: data?['text'] ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
