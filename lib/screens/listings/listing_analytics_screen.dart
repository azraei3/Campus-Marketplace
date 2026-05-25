import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/listing_model.dart';
import '../../services/listing_service.dart';

class ListingAnalyticsScreen extends StatefulWidget {
  final String listingId;
  const ListingAnalyticsScreen({super.key, required this.listingId});

  @override
  State<ListingAnalyticsScreen> createState() => _ListingAnalyticsScreenState();
}

class _ListingAnalyticsScreenState extends State<ListingAnalyticsScreen> {
  final ListingService _listingService = ListingService();

  Uint8List? _decode(String url) {
    if (url.isEmpty) return null;
    try {
      return base64Decode(url);
    } on FormatException {
      return null;
    }
  }

  double _average(List<int> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<int>(0, (a, b) => a + b);
    return sum / values.length;
  }

  String _compareLabel(int mine, double avg) {
    if (avg == 0) return 'You have no other listings to compare with.';
    final ratio = mine / avg;
    if (ratio >= 2) return '${ratio.toStringAsFixed(1)}× your average.';
    if (ratio >= 1.1) return '${(ratio * 100 - 100).toStringAsFixed(0)}% above your average.';
    if (ratio >= 0.9) return 'Around your average.';
    if (ratio == 0) return 'No activity yet.';
    return '${(100 - ratio * 100).toStringAsFixed(0)}% below your average.';
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Listing Analytics')),
      body: StreamBuilder<ListingModel?>(
        stream: _listingService.streamListing(widget.listingId),
        builder: (context, listingSnap) {
          if (listingSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (listingSnap.hasError) {
            return Center(child: Text('Error: ${listingSnap.error}'));
          }
          final listing = listingSnap.data;
          if (listing == null) {
            return const Center(child: Text('Listing not found.'));
          }
          if (uid == null || listing.sellerId != uid) {
            return const Center(
              child: Text('You can only view analytics for your own listings.'),
            );
          }

          return StreamBuilder<List<ListingModel>>(
            stream: _listingService.streamMyListings(),
            builder: (context, myListingsSnap) {
              if (myListingsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final myListings = (myListingsSnap.data ?? <ListingModel>[])
                  .where((l) => l.listingId != listing.listingId)
                  .toList();

              final double avgViews =
                  _average(myListings.map((l) => l.viewCount).toList());
              final double avgSaves =
                  _average(myListings.map((l) => l.saveCount).toList());
              final double avgRequests =
                  _average(myListings.map((l) => l.requestCount).toList());

              final int daysActive = listing.createdAt == null
                  ? 0
                  : DateTime.now().difference(listing.createdAt!).inDays;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(listing),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Views',
                          listing.viewCount,
                          Icons.remove_red_eye,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Saves',
                          listing.saveCount,
                          Icons.favorite,
                          Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Requests',
                          listing.requestCount,
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoTile('Days active', '$daysActive day${daysActive == 1 ? '' : 's'}'),
                  _infoTile('Status', listing.status),
                  const SizedBox(height: 20),
                  const Text(
                    'Compared to your other listings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _comparisonRow('Views', listing.viewCount, avgViews, Colors.blue),
                  _comparisonRow('Saves', listing.saveCount, avgSaves, Colors.pink),
                  _comparisonRow(
                      'Requests', listing.requestCount, avgRequests, Colors.orange),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(ListingModel listing) {
    final bytes = _decode(listing.imageUrl);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, color: Colors.white),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${listing.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, int mine, double avg, Color color) {
    final double maxBar = (avg * 2).clamp(1, double.infinity);
    final double mineFraction = (mine / maxBar).clamp(0.0, 1.0);
    final double avgFraction = (avg / maxBar).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _compareLabel(mine, avg),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _bar('This listing: $mine', mineFraction, color),
          const SizedBox(height: 4),
          _bar(
            'Your average: ${avg.toStringAsFixed(1)}',
            avgFraction,
            color.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, double fraction, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth * fraction;
        return Stack(
          children: [
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 18,
              width: width < 4 ? 4 : width,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
