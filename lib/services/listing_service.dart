import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  static const int _maxImageBytes = 700 * 1024;

  CollectionReference<ListingModel> get _collection => _db
      .collection('listings')
      .withConverter<ListingModel>(
        fromFirestore: ListingModel.fromFirestore,
        toFirestore: (ListingModel listing, _) => listing.toFirestore(),
      );

  Future<String?> pickAndEncodeImage({required ImageSource source}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );

    if (picked == null) {
      return null;
    }

    final Uint8List bytes = await picked.readAsBytes();

    if (bytes.lengthInBytes > _maxImageBytes) {
      throw Exception(
        'Image is too large after compression. Please pick a smaller image.',
      );
    }

    return base64Encode(bytes);
  }

  Future<String> createListing({
    required String title,
    required double price,
    required String category,
    required String condition,
    required String description,
    required String location,
    required String imageBase64,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to create a listing.');
    }

    if (imageBase64.isEmpty) {
      throw Exception('An image is required to publish a listing.');
    }

    final DocumentReference<ListingModel> docRef = _collection.doc();

    bool sellerIsVerified = user.emailVerified;
    if (!sellerIsVerified) {
      final DocumentSnapshot<Map<String, dynamic>> userSnap =
          await _db.collection('users').doc(user.uid).get();
      sellerIsVerified = userSnap.data()?['isVerified'] == true;
    }

    final ListingModel listing = ListingModel(
      listingId: docRef.id,
      sellerId: user.uid,
      sellerName: user.displayName ?? 'Unknown Seller',
      sellerIsVerified: sellerIsVerified,
      title: title,
      price: price,
      category: category,
      condition: condition,
      description: description,
      location: location,
      imageUrl: imageBase64,
      status: ListingStatus.available,
    );

    await docRef.set(listing);
    return docRef.id;
  }

  Future<void> updateListing({
    required String listingId,
    required String title,
    required double price,
    required String category,
    required String condition,
    required String description,
    required String location,
    required String imageBase64,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to update a listing.');
    }

    final DocumentSnapshot<ListingModel> snapshot =
        await _collection.doc(listingId).get();
    final ListingModel? existing = snapshot.data();

    if (existing == null) {
      throw Exception('Listing not found.');
    }

    if (existing.sellerId != user.uid) {
      throw Exception('You can only edit your own listings.');
    }

    await _db.collection('listings').doc(listingId).update({
      'title': title,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'location': location,
      'imageUrl': imageBase64,
    });
  }

  Future<void> deleteListing(String listingId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to delete a listing.');
    }

    final DocumentSnapshot<ListingModel> snapshot =
        await _collection.doc(listingId).get();
    final ListingModel? existing = snapshot.data();

    if (existing == null) {
      throw Exception('Listing not found.');
    }

    if (existing.sellerId != user.uid) {
      throw Exception('You can only delete your own listings.');
    }

    if (existing.status != ListingStatus.available) {
      throw Exception(
        'You cannot delete a listing that is reserved or sold.',
      );
    }

    await _db.collection('listings').doc(listingId).delete();
  }

  Future<void> updateStatus({
    required String listingId,
    required String status,
  }) async {
    if (!ListingStatus.values.contains(status)) {
      throw Exception('Invalid listing status.');
    }
    await _db.collection('listings').doc(listingId).update({'status': status});
  }

  Stream<List<ListingModel>> streamAvailableListings({String? category}) {
    Query<ListingModel> query = _collection
        .where('status', isEqualTo: ListingStatus.available);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => d.data()).toList()
            ..sort((a, b) {
              final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            }),
        );
  }

  Stream<List<ListingModel>> streamMyListings() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream<List<ListingModel>>.empty();
    }

    return _collection
        .where('sellerId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => d.data()).toList()
            ..sort((a, b) {
              final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            }),
        );
  }

  Future<ListingModel?> getListing(String listingId) async {
    final DocumentSnapshot<ListingModel> snap =
        await _collection.doc(listingId).get();
    return snap.data();
  }

  Stream<ListingModel?> streamListing(String listingId) {
    return _collection
        .doc(listingId)
        .snapshots()
        .map((snap) => snap.data());
  }

  Future<void> incrementViewCount(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final DocumentSnapshot<ListingModel> snap =
        await _collection.doc(listingId).get();
    final listing = snap.data();
    if (listing == null) return;
    if (listing.sellerId == user.uid) return;
    await _db.collection('listings').doc(listingId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Stream<List<ListingModel>> streamListingsBySeller(String sellerId) {
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

  Future<void> toggleSaved(String listingId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to save items.');
    }

    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('saved')
        .doc(listingId);

    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    final WriteBatch batch = _db.batch();
    if (snap.exists) {
      batch.delete(ref);
      batch.update(_db.collection('listings').doc(listingId), {
        'saveCount': FieldValue.increment(-1),
      });
    } else {
      batch.set(ref, {'savedAt': FieldValue.serverTimestamp()});
      batch.update(_db.collection('listings').doc(listingId), {
        'saveCount': FieldValue.increment(1),
      });
    }
    await batch.commit();
  }

  Stream<bool> streamIsSaved(String listingId) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream<bool>.value(false);
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('saved')
        .doc(listingId)
        .snapshots()
        .map((snap) => snap.exists);
  }

  Stream<List<String>> streamSavedListingIds() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream<List<String>>.value(<String>[]);
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('saved')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
