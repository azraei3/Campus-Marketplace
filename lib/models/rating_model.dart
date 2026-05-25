import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String ratingId;
  final String reviewerId;
  final String reviewerName;
  final String sellerId;
  final String listingId;
  final String requestId;
  final int score;
  final String comment;
  final DateTime? createdAt;

  RatingModel({
    required this.ratingId,
    required this.reviewerId,
    required this.reviewerName,
    required this.sellerId,
    required this.listingId,
    required this.requestId,
    required this.score,
    required this.comment,
    this.createdAt,
  });

  factory RatingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return RatingModel(
      ratingId: snapshot.id,
      reviewerId: data?['reviewerId'] ?? '',
      reviewerName: data?['reviewerName'] ?? 'Unknown',
      sellerId: data?['sellerId'] ?? '',
      listingId: data?['listingId'] ?? '',
      requestId: data?['requestId'] ?? '',
      score: (data?['score'] is num) ? (data!['score'] as num).toInt() : 0,
      comment: data?['comment'] ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'sellerId': sellerId,
      'listingId': listingId,
      'requestId': requestId,
      'score': score,
      'comment': comment,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
