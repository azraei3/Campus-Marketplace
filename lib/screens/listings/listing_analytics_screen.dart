import 'dart:convert';
import 'dart:math' as math;
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
    if (avg == 0) return 'Solo Listing';
    final ratio = mine / avg;
    if (ratio >= 2) return '${ratio.toStringAsFixed(1)}× average';
    if (ratio >= 1.1) return '+${(ratio * 100 - 100).toStringAsFixed(0)}% above avg';
    if (ratio >= 0.9) return 'Average tier';
    if (ratio == 0) return 'No activity yet';
    return '-${(100 - ratio * 100).toStringAsFixed(0)}% below avg';
  }

  Widget _buildStatusBadge(String status) {
    final Color color = status == ListingStatus.available
        ? Colors.green
        : status == ListingStatus.reserved
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Analytics'),
        elevation: 0,
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildHeader(listing),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Views',
                          listing.viewCount,
                          Icons.visibility_rounded,
                          Colors.blue.shade700,
                          [const Color(0xFFEBF8FF), const Color(0xFFE0F2FE)],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          'Saves',
                          listing.saveCount,
                          Icons.favorite_rounded,
                          Colors.pink.shade600,
                          [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3)],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          'Requests',
                          listing.requestCount,
                          Icons.shopping_bag_rounded,
                          Colors.orange.shade700,
                          [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(daysActive),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 20, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        'Comparison Insights',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _comparisonCard([
                    _comparisonRow(
                      label: 'Views',
                      icon: Icons.visibility_rounded,
                      mine: listing.viewCount,
                      avg: avgViews,
                      gradientColors: [const Color(0xFF60A5FA), Colors.blue.shade700],
                    ),
                    _comparisonRow(
                      label: 'Saves',
                      icon: Icons.favorite_rounded,
                      mine: listing.saveCount,
                      avg: avgSaves,
                      gradientColors: [const Color(0xFFF472B6), Colors.pink.shade600],
                    ),
                    _comparisonRow(
                      label: 'Requests',
                      icon: Icons.shopping_bag_rounded,
                      mine: listing.requestCount,
                      avg: avgRequests,
                      gradientColors: [const Color(0xFFFB923C), Colors.orange.shade700],
                    ),
                  ]),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'RM ${listing.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusBadge(listing.status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color, List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(int daysActive) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Active',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$daysActive day${daysActive == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 32,
              width: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.trending_up_rounded, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Active Track',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonCard(List<Widget> rows) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: rows,
        ),
      ),
    );
  }

  Widget _comparisonRow({
    required String label,
    required IconData icon,
    required int mine,
    required double avg,
    required List<Color> gradientColors,
  }) {
    final double maxVal = math.max(mine.toDouble(), avg).clamp(1.0, double.infinity);
    final double mineFraction = mine / maxVal;
    final double avgFraction = avg / maxVal;

    final ratioLabel = _compareLabel(mine, avg);
    final Color mainColor = gradientColors.last;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: mainColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ratioLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCustomBar(
            label: 'This listing',
            fraction: mineFraction,
            gradientColors: gradientColors,
            valueText: '$mine',
          ),
          const SizedBox(height: 8),
          _buildCustomBar(
            label: 'Your average',
            gradientColors: [const Color(0xFFE2E8F0), const Color(0xFF94A3B8)],
            fraction: avgFraction,
            valueText: avg.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBar({
    required String label,
    required double fraction,
    required List<Color> gradientColors,
    required String valueText,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double barWidth = fraction * maxWidth;
              return Container(
                height: 10,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  width: barWidth.clamp(6.0, maxWidth),
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.last.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            valueText,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: gradientColors.last == const Color(0xFF94A3B8)
                  ? Colors.grey.shade600
                  : gradientColors.last,
            ),
          ),
        ),
      ],
    );
  }
}
