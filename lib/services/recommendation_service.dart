import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/listing_model.dart';

class RecommendationResult {
  final List<ListingModel> listings;
  final String? trendingTag;

  RecommendationResult({required this.listings, this.trendingTag});
}

class RecommendationService {
  RecommendationService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _trendingEndpoint =
      'https://jsonplaceholder.typicode.com/posts/1';

  Future<RecommendationResult> recommendationsForListing(
    String listingId,
  ) async {
    final ListingModel? current = await _getListing(listingId);
    if (current == null) {
      return RecommendationResult(listings: <ListingModel>[]);
    }

    final results = await Future.wait<dynamic>([
      _firestoreRecommendations(current),
      _fetchTrendingTag(),
    ]);

    final List<ListingModel> listings = results[0] as List<ListingModel>;
    final String? trendingTag = results[1] as String?;

    return RecommendationResult(
      listings: listings,
      trendingTag: trendingTag,
    );
  }

  Future<ListingModel?> _getListing(String listingId) async {
    final snap = await _db
        .collection('listings')
        .withConverter<ListingModel>(
          fromFirestore: ListingModel.fromFirestore,
          toFirestore: (ListingModel l, _) => l.toFirestore(),
        )
        .doc(listingId)
        .get();
    return snap.data();
  }

  Future<List<ListingModel>> _firestoreRecommendations(
    ListingModel current,
  ) async {
    final String? currentUid = _auth.currentUser?.uid;
    final QuerySnapshot<ListingModel> snap = await _db
        .collection('listings')
        .withConverter<ListingModel>(
          fromFirestore: ListingModel.fromFirestore,
          toFirestore: (ListingModel l, _) => l.toFirestore(),
        )
        .where('category', isEqualTo: current.category)
        .where('status', isEqualTo: ListingStatus.available)
        .limit(20)
        .get();

    final all = snap.docs.map((d) => d.data()).where((l) {
      if (l.listingId == current.listingId) return false;
      if (currentUid != null && l.sellerId == currentUid) return false;
      return true;
    }).toList();

    all.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return all.take(4).toList();
  }

  Future<String?> _fetchTrendingTag() async {
    try {
      final response = await _http
          .get(Uri.parse(_trendingEndpoint))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is Map && body['title'] is String) {
        final String raw = (body['title'] as String).trim();
        if (raw.isEmpty) return null;
        final String firstWord = raw.split(' ').first;
        return 'Trending · ${firstWord[0].toUpperCase()}${firstWord.substring(1)}';
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
