import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_model.dart';
import '../../models/rating_model.dart';
import '../../models/user_model.dart';
import '../../services/listing_service.dart';
import '../../services/rating_service.dart';
import '../../services/user_service.dart';
import '../listings/widgets/listing_card.dart';
import '../widgets/star_rating.dart';
import '../widgets/verified_badge.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final ratingService = RatingService();
    final listingService = ListingService();

    return Scaffold(
      appBar: AppBar(title: const Text('Seller Profile')),
      body: StreamBuilder<UserModel?>(
        stream: userService.streamUser(sellerId),
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
              Container(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Listings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<List<ListingModel>>(
                stream: listingService.streamListingsBySeller(sellerId),
                builder: (context, listingSnap) {
                  if (listingSnap.connectionState == ConnectionState.waiting) {
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
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: listings.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Reviews',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<List<RatingModel>>(
                stream: ratingService.streamRatingsForSeller(sellerId),
                builder: (context, ratingSnap) {
                  if (ratingSnap.connectionState == ConnectionState.waiting) {
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
                  final ratings = ratingSnap.data ?? <RatingModel>[];
                  if (ratings.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                StarRating(value: rating.score.toDouble(), size: 14),
              ],
            ),
            if (rating.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  rating.createdAt!.toLocal().toString().split(' ').first,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            if (rating.comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(rating.comment, style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
