import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<RatingModel> get _collection => _db
      .collection('ratings')
      .withConverter<RatingModel>(
        fromFirestore: RatingModel.fromFirestore,
        toFirestore: (RatingModel r, _) => r.toFirestore(),
      );

  Future<RatingModel?> getRatingForRequest(String requestId) async {
    final snap = await _collection
        .where('requestId', isEqualTo: requestId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  Stream<List<RatingModel>> streamRatingsForSeller(String sellerId) {
    return _collection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> submitRating({
    required String sellerId,
    required String listingId,
    required String requestId,
    required int score,
    required String comment,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to submit a rating.');
    }
    if (score < 1 || score > 5) {
      throw Exception('Please choose a score from 1 to 5.');
    }
    if (sellerId == user.uid) {
      throw Exception('You cannot rate yourself.');
    }
    if (comment.length > 200) {
      throw Exception('Comment must be 200 characters or fewer.');
    }

    final existing = await getRatingForRequest(requestId);
    if (existing != null) {
      throw Exception('You have already rated this transaction.');
    }

    final DocumentReference<RatingModel> ratingRef = _collection.doc();
    final DocumentReference<Map<String, dynamic>> sellerRef =
        _db.collection('users').doc(sellerId);

    await _db.runTransaction((tx) async {
      final sellerSnap = await tx.get(sellerRef);
      final sellerData = sellerSnap.data();
      final double currentAvg = (sellerData?['averageRating'] is num)
          ? (sellerData!['averageRating'] as num).toDouble()
          : 0.0;
      final int currentTotal = (sellerData?['totalRatings'] is num)
          ? (sellerData!['totalRatings'] as num).toInt()
          : 0;

      final int newTotal = currentTotal + 1;
      final double newAvg =
          ((currentAvg * currentTotal) + score) / newTotal;

      final RatingModel rating = RatingModel(
        ratingId: ratingRef.id,
        reviewerId: user.uid,
        reviewerName: user.displayName ?? 'Unknown',
        sellerId: sellerId,
        listingId: listingId,
        requestId: requestId,
        score: score,
        comment: comment,
      );

      tx.set(_db.collection('ratings').doc(ratingRef.id), rating.toFirestore());
      tx.set(
        sellerRef,
        {'averageRating': newAvg, 'totalRatings': newTotal},
        SetOptions(merge: true),
      );
    });
  }
}
