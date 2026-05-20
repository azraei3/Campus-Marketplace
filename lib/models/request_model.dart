import 'package:cloud_firestore/cloud_firestore.dart';

class RequestStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String completed = 'completed';

  static const List<String> values = [pending, accepted, rejected, completed];
}

class RequestModel {
  final String requestId;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String status;
  final String message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RequestModel({
    required this.requestId,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.status,
    required this.message,
    this.createdAt,
    this.updatedAt,
  });

  factory RequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return RequestModel(
      requestId: snapshot.id,
      listingId: data?['listingId'] ?? '',
      listingTitle: data?['listingTitle'] ?? '',
      listingImage: data?['listingImage'] ?? '',
      buyerId: data?['buyerId'] ?? '',
      buyerName: data?['buyerName'] ?? 'Unknown Buyer',
      sellerId: data?['sellerId'] ?? '',
      status: data?['status'] ?? RequestStatus.pending,
      message: data?['message'] ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'status': status,
      'message': message,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
