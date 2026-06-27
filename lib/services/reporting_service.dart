import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserReportData {
  final int totalListings;
  final int activeListings;
  final int totalViews;
  final int totalSaves;
  final int totalRequestsReceived;
  final int totalRequestsSent;
  final Map<String, int> categoryDistribution;
  
  UserReportData({
    required this.totalListings,
    required this.activeListings,
    required this.totalViews,
    required this.totalSaves,
    required this.totalRequestsReceived,
    required this.totalRequestsSent,
    required this.categoryDistribution,
  });

  String toCsvString() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Metric,Value');
    buffer.writeln('Total Listings,$totalListings');
    buffer.writeln('Active Listings,$activeListings');
    buffer.writeln('Total Views,$totalViews');
    buffer.writeln('Total Saves,$totalSaves');
    buffer.writeln('Requests Received,$totalRequestsReceived');
    buffer.writeln('Requests Sent,$totalRequestsSent');
    buffer.writeln('');
    buffer.writeln('Category,Listing Count');
    categoryDistribution.forEach((cat, val) {
      buffer.writeln('$cat,$val');
    });
    return buffer.toString();
  }
}

class ReportingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserReportData?> generateUserReport() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final String uid = user.uid;


    final listingsSnap = await _db
        .collection('listings')
        .where('sellerId', isEqualTo: uid)
        .get();

    int totalListings = listingsSnap.docs.length;
    int activeListings = 0;
    int totalViews = 0;
    int totalSaves = 0;
    Map<String, int> categoryDistribution = {};

    for (var doc in listingsSnap.docs) {
      final data = doc.data();
      
      if (data['status'] == 'available') {
        activeListings++;
      }
      
      totalViews += (data['viewCount'] as num?)?.toInt() ?? 0;
      totalSaves += (data['saveCount'] as num?)?.toInt() ?? 0;
      
      final String category = data['category'] ?? 'Other';
      categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
    }


    final incomingRequestsSnap = await _db
        .collection('requests')
        .where('sellerId', isEqualTo: uid)
        .count()
        .get();
        

    final sentRequestsSnap = await _db
        .collection('requests')
        .where('buyerId', isEqualTo: uid)
        .count()
        .get();

    return UserReportData(
      totalListings: totalListings,
      activeListings: activeListings,
      totalViews: totalViews,
      totalSaves: totalSaves,
      totalRequestsReceived: incomingRequestsSnap.count ?? 0,
      totalRequestsSent: sentRequestsSnap.count ?? 0,
      categoryDistribution: categoryDistribution,
    );
  }
}
