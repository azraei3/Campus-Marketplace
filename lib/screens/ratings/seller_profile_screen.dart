import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_model.dart';
import '../../models/rating_model.dart';
import '../../models/user_model.dart';
import '../../services/ai_service.dart';
import '../../services/listing_service.dart';
import '../../services/rating_service.dart';
import '../../services/user_service.dart';
import '../listings/widgets/listing_card.dart';
import '../widgets/star_rating.dart';
import '../widgets/verified_badge.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final UserService _userService = UserService();
  final RatingService _ratingService = RatingService();
  final ListingService _listingService = ListingService();
  // Summary state
  String? _reputationSummary;
  bool _isLoadingSummary = false;
  bool _summaryGenerated = false;

  Future<void> _generateReputationSummary({
    required UserModel seller,
    required List<RatingModel> ratings,
  }) async {
    if (_isLoadingSummary || _summaryGenerated) return;
    setState(() => _isLoadingSummary = true);

    try {
      final comments = ratings.map((r) => r.comment).toList();
      final summary = await AiService.summarizeSellerReputation(
        sellerName: seller.name,
        averageRating: seller.averageRating,
        totalRatings: seller.totalRatings,
        reviewComments: comments,
      );
      if (!mounted) return;
      setState(() {
        _reputationSummary = summary;
        _summaryGenerated = true;
        _isLoadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Profile')),
      body: StreamBuilder<UserModel?>(
        stream: _userService.streamUser(widget.sellerId),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnap.hasError) {
            return Center(child: Text('Error: ${userSnap.error}'));
          }
          final UserModel? seller = userSnap.data;
          if (seller == null) {
            return const Center(child: Text('Seller not found.'));
          }

          return ListView(
            children: [
              // Main Header
              Container(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.15),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondary,
                      child: const Icon(Icons.person,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          seller.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (seller.isVerified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StarRating(value: seller.averageRating, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          seller.totalRatings > 0
                              ? '${seller.averageRating.toStringAsFixed(1)} · ${seller.totalRatings} review${seller.totalRatings == 1 ? '' : 's'}'
                              : 'No reviews yet',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Reputation block
              StreamBuilder<List<RatingModel>>(
                stream:
                    _ratingService.streamRatingsForSeller(widget.sellerId),
                builder: (context, ratingSnap) {
                  final ratings = ratingSnap.data ?? [];

                  // Auto-generate summary once ratings load
                  if (ratings.isNotEmpty &&
                      !_summaryGenerated &&
                      !_isLoadingSummary) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _generateReputationSummary(
                          seller: seller, ratings: ratings);
                    });
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildReputationCard(seller, ratings),
                  );
                },
              ),
              // Active products
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Listings',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<List<ListingModel>>(
                stream:
                    _listingService.streamListingsBySeller(widget.sellerId),
                builder: (context, listingSnap) {
                  if (listingSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (listingSnap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: ${listingSnap.error}'),
                    );
                  }
                  final listings = (listingSnap.data ?? <ListingModel>[])
                      .where((l) => l.status == ListingStatus.available)
                      .toList();
                  if (listings.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        'No active listings.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: listings.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final l = listings[i];
                        return SizedBox(
                          width: 160,
                          child: ListingCard(
                            listing: l,
                            onTap: () =>
                                context.push('/listings/${l.listingId}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              // Feedback list
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Reviews',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<List<RatingModel>>(
                stream:
                    _ratingService.streamRatingsForSeller(widget.sellerId),
                builder: (context, ratingSnap) {
                  if (ratingSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (ratingSnap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: ${ratingSnap.error}'),
                    );
                  }
                  final ratings = ratingSnap.data ?? [];
                  if (ratings.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        'No reviews yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Column(
                    children: ratings
                        .map((r) => _buildReviewTile(context, r))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
  // Reputation card component
  Widget _buildReputationCard(UserModel seller, List<RatingModel> ratings) {
    final bool hasRatings = seller.totalRatings > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B3FE4).withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7B3FE4).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B3FE4), Color(0xFFB06AF5)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Reputation Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B3FE4),
                ),
              ),
              const Spacer(),
              if (!hasRatings)
                const Text(
                  'No reviews yet',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Summary content
          if (_isLoadingSummary)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7B3FE4)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI is reading ${seller.totalRatings} review${seller.totalRatings == 1 ? '' : 's'}...',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          else if (_reputationSummary != null)
            Text(
              _reputationSummary!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.55,
              ),
            )
          else if (!hasRatings)
            Text(
              '${seller.name} is a new seller on Campus Marketplace. Be the first to trade and leave a review!',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            )
          else
            // Fallback: auto-trigger manually if something went wrong
            GestureDetector(
              onTap: () => _generateReputationSummary(
                  seller: seller, ratings: ratings),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B3FE4).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh,
                        size: 14, color: Color(0xFF7B3FE4)),
                    SizedBox(width: 6),
                    Text(
                      'Generate AI Summary',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF7B3FE4)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(BuildContext context, RatingModel rating) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rating.reviewerName,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                StarRating(value: rating.score.toDouble(), size: 14),
              ],
            ),
            if (rating.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  rating.createdAt!
                      .toLocal()
                      .toString()
                      .split(' ')
                      .first,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11),
                ),
              ),
            if (rating.comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(rating.comment,
                    style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
