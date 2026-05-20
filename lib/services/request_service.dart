import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/listing_model.dart';
import '../models/request_model.dart';

class RequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<RequestModel> get _collection => _db
      .collection('requests')
      .withConverter<RequestModel>(
        fromFirestore: RequestModel.fromFirestore,
        toFirestore: (RequestModel r, _) => r.toFirestore(),
      );

  Future<String> sendRequest({
    required ListingModel listing,
    required String message,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to send a request.');
    }

    if (listing.sellerId == user.uid) {
      throw Exception('You cannot send a request on your own listing.');
    }

    if (listing.status != ListingStatus.available) {
      throw Exception(
        'This listing is no longer available.',
      );
    }

    final QuerySnapshot<RequestModel> existing = await _collection
        .where('listingId', isEqualTo: listing.listingId)
        .where('buyerId', isEqualTo: user.uid)
        .where('status', whereIn: [
          RequestStatus.pending,
          RequestStatus.accepted,
        ])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
        'You already have an active request for this listing.',
      );
    }

    final DocumentReference<RequestModel> docRef = _collection.doc();

    final RequestModel request = RequestModel(
      requestId: docRef.id,
      listingId: listing.listingId,
      listingTitle: listing.title,
      listingImage: listing.imageUrl,
      buyerId: user.uid,
      buyerName: user.displayName ?? 'Unknown Buyer',
      sellerId: listing.sellerId,
      status: RequestStatus.pending,
      message: message,
    );

    final WriteBatch batch = _db.batch();
    batch.set(_db.collection('requests').doc(docRef.id), request.toFirestore());
    batch.update(_db.collection('listings').doc(listing.listingId), {
      'requestCount': FieldValue.increment(1),
    });
    await batch.commit();
    return docRef.id;
  }

  Future<RequestModel?> getRequest(String requestId) async {
    final snap = await _collection.doc(requestId).get();
    return snap.data();
  }

  Stream<List<RequestModel>> streamMyRequests({String? status}) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream<List<RequestModel>>.value(<RequestModel>[]);
    }

    Query<RequestModel> query =
        _collection.where('buyerId', isEqualTo: user.uid);

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) {
        final aTime =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<List<RequestModel>> streamIncomingRequests({String? status}) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream<List<RequestModel>>.value(<RequestModel>[]);
    }

    Query<RequestModel> query =
        _collection.where('sellerId', isEqualTo: user.uid);

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) {
        final aTime =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<bool> listingHasAcceptedRequest(String listingId) async {
    final QuerySnapshot<RequestModel> snap = await _collection
        .where('listingId', isEqualTo: listingId)
        .where('status', isEqualTo: RequestStatus.accepted)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> acceptRequest({
    required String requestId,
    String responseMessage = '',
  }) async {
    await _changeStatus(
      requestId: requestId,
      newStatus: RequestStatus.accepted,
      newListingStatus: ListingStatus.reserved,
      responseMessage: responseMessage,
    );
  }

  Future<void> rejectRequest({
    required String requestId,
    String responseMessage = '',
  }) async {
    await _changeStatus(
      requestId: requestId,
      newStatus: RequestStatus.rejected,
      newListingStatus: null,
      responseMessage: responseMessage,
    );
  }

  Future<void> completeRequest({required String requestId}) async {
    await _changeStatus(
      requestId: requestId,
      newStatus: RequestStatus.completed,
      newListingStatus: ListingStatus.sold,
    );
  }

  Future<void> _changeStatus({
    required String requestId,
    required String newStatus,
    String? newListingStatus,
    String responseMessage = '',
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in.');
    }

    final DocumentReference<RequestModel> requestRef = _collection.doc(requestId);

    await _db.runTransaction((tx) async {
      final DocumentSnapshot<RequestModel> snap = await tx.get(requestRef);
      final RequestModel? request = snap.data();

      if (request == null) {
        throw Exception('Request not found.');
      }

      if (request.sellerId != user.uid) {
        throw Exception('Only the seller can update this request.');
      }

      if (newStatus == RequestStatus.accepted ||
          newStatus == RequestStatus.rejected) {
        if (request.status != RequestStatus.pending) {
          throw Exception(
            'Only pending requests can be accepted or rejected.',
          );
        }
      }

      if (newStatus == RequestStatus.completed &&
          request.status != RequestStatus.accepted) {
        throw Exception(
          'Only accepted requests can be marked as completed.',
        );
      }

      tx.update(_db.collection('requests').doc(requestId), {
        'status': newStatus,
        if (responseMessage.isNotEmpty) 'responseMessage': responseMessage,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newListingStatus != null) {
        tx.update(
          _db.collection('listings').doc(request.listingId),
          {'status': newListingStatus},
        );
      }
    });
  }
}
