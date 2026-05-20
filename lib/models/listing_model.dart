import 'package:cloud_firestore/cloud_firestore.dart';

class ListingCategory {
  static const String textbooks = 'Textbooks';
  static const String electronics = 'Electronics';
  static const String clothing = 'Clothing';
  static const String furniture = 'Furniture';
  static const String sports = 'Sports';
  static const String vehicles = 'Vehicles';
  static const String free = 'Free';
  static const String others = 'Others';

  static const List<String> values = [
    textbooks,
    electronics,
    clothing,
    furniture,
    sports,
    vehicles,
    free,
    others,
  ];
}

class ListingCondition {
  static const String likeNew = 'Like New';
  static const String lightlyUsed = 'Lightly Used';
  static const String wellUsed = 'Well Used';

  static const List<String> values = [likeNew, lightlyUsed, wellUsed];
}

class ListingStatus {
  static const String available = 'available';
  static const String reserved = 'reserved';
  static const String sold = 'sold';

  static const List<String> values = [available, reserved, sold];
}

class ListingModel {
  final String listingId;
  final String sellerId;
  final String sellerName;
  final bool sellerIsVerified;
  final String title;
  final double price;
  final String category;
  final String condition;
  final String description;
  final String location;
  final String imageUrl;
  final String status;
  final int viewCount;
  final int saveCount;
  final int requestCount;
  final DateTime? createdAt;

  ListingModel({
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    this.sellerIsVerified = false,
    required this.title,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.status,
    this.viewCount = 0,
    this.saveCount = 0,
    this.requestCount = 0,
    this.createdAt,
  });

  factory ListingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return ListingModel(
      listingId: snapshot.id,
      sellerId: data?['sellerId'] ?? '',
      sellerName: data?['sellerName'] ?? 'Unknown Seller',
      sellerIsVerified: data?['sellerIsVerified'] == true,
      title: data?['title'] ?? '',
      price: (data?['price'] is num) ? (data!['price'] as num).toDouble() : 0.0,
      category: data?['category'] ?? ListingCategory.others,
      condition: data?['condition'] ?? ListingCondition.wellUsed,
      description: data?['description'] ?? '',
      location: data?['location'] ?? '',
      imageUrl: data?['imageUrl'] ?? '',
      status: data?['status'] ?? ListingStatus.available,
      viewCount: (data?['viewCount'] is num)
          ? (data!['viewCount'] as num).toInt()
          : 0,
      saveCount: (data?['saveCount'] is num)
          ? (data!['saveCount'] as num).toInt()
          : 0,
      requestCount: (data?['requestCount'] is num)
          ? (data!['requestCount'] as num).toInt()
          : 0,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerIsVerified': sellerIsVerified,
      'title': title,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'status': status,
      'viewCount': viewCount,
      'saveCount': saveCount,
      'requestCount': requestCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ListingModel copyWith({
    String? listingId,
    String? sellerId,
    String? sellerName,
    bool? sellerIsVerified,
    String? title,
    double? price,
    String? category,
    String? condition,
    String? description,
    String? location,
    String? imageUrl,
    String? status,
    int? viewCount,
    int? saveCount,
    int? requestCount,
    DateTime? createdAt,
  }) {
    return ListingModel(
      listingId: listingId ?? this.listingId,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
      requestCount: requestCount ?? this.requestCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
