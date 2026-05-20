import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_model.dart';
import '../../services/chat_service.dart';
import '../../services/listing_service.dart';
import '../../services/recommendation_service.dart';
import '../../services/request_service.dart';
import '../widgets/verified_badge.dart';
import 'widgets/listing_card.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final ListingService _listingService = ListingService();
  final RequestService _requestService = RequestService();
  final ChatService _chatService = ChatService();
  final RecommendationService _recommendationService = RecommendationService();

  late final Stream<ListingModel?> _listingStream;
  late Future<RecommendationResult> _recommendationsFuture;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _listingStream = _listingService.streamListing(widget.listingId);
    _recommendationsFuture =
        _recommendationService.recommendationsForListing(widget.listingId);
    _incrementViewOnce();
  }

  Future<void> _incrementViewOnce() async {
    if (_viewCounted) return;
    _viewCounted = true;
    try {
      await _listingService.incrementViewCount(widget.listingId);
    } catch (_) {
    }
  }

  Uint8List? _decode(String url) {
    if (url.isEmpty) return null;
    try {
      return base64Decode(url);
    } on FormatException {
      return null;
    }
  }

  Future<void> _onSavePressed() async {
    try {
      await _listingService.toggleSaved(widget.listingId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: StreamBuilder<ListingModel?>(
        stream: _listingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error: ${snapshot.error}',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final listing = snapshot.data;
          if (listing == null) {
            return const Center(
              child: Text('This listing no longer exists.'),
            );
          }

          final Uint8List? bytes = _decode(listing.imageUrl);
          final bool isOwner = currentUid != null &&
              currentUid == listing.sellerId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.secondary,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusBadge(listing.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${listing.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSellerRow(listing),
                      _buildInfoRow(
                        Icons.label_outline,
                        'Category',
                        listing.category,
                      ),
                      _buildInfoRow(
                        Icons.star_border,
                        'Condition',
                        listing.condition,
                      ),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Location',
                        listing.location.isEmpty ? '-' : listing.location,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listing.description.isEmpty
                            ? 'No description provided.'
                            : listing.description,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      if (!isOwner) _buildBuyerActions(listing),
                      if (isOwner) _buildOwnerActions(listing),
                    ],
                  ),
                ),
                _buildRecommendationSection(listing),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSellerRow(ListingModel listing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              'Seller',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => context.push('/sellers/${listing.sellerId}'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      listing.sellerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (listing.sellerIsVerified) ...[
                    const SizedBox(width: 4),
                    const VerifiedBadge(size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerActions(ListingModel listing) {
    final bool canRequest = listing.status == ListingStatus.available;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StreamBuilder<bool>(
                stream: _listingService.streamIsSaved(listing.listingId),
                initialData: false,
                builder: (context, snap) {
                  final saved = snap.data ?? false;
                  return OutlinedButton.icon(
                    onPressed: _onSavePressed,
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                    label: Text(saved ? 'Saved' : 'Save'),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canRequest ? () => _sendRequest(listing) : null,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Request'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openChat(listing),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contact Seller'),
          ),
        ),
        if (!canRequest)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'This listing is ${listing.status} and cannot be requested.',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
      ],
    );
  }

  Future<void> _openChat(ListingModel listing) async {
    try {
      final String chatId =
          await _chatService.getOrCreateChatForListing(listing);
      if (!mounted) return;
      context.push('/chats/$chatId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _sendRequest(ListingModel listing) async {
    final TextEditingController controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send purchase request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Send a request to ${listing.sellerName} for "${listing.title}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Optional message',
                border: OutlineInputBorder(),
                hintText: 'Hi, is this still available?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _requestService.sendRequest(
        listing: listing,
        message: controller.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildOwnerActions(ListingModel listing) {
    final bool canModify = listing.status == ListingStatus.available;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!canModify)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'This listing is ${listing.status} and cannot be edited or deleted.',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canModify
                    ? () => context.push(
                          '/listings/${listing.listingId}/edit',
                        )
                    : null,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canModify ? () => _confirmDelete(listing) : null,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push('/listings/${listing.listingId}/analytics'),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View Analytics'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(ListingModel listing) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text(
          'Are you sure you want to delete "${listing.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _listingService.deleteListing(listing.listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildRecommendationSection(ListingModel listing) {
    return FutureBuilder<RecommendationResult>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More in ${listing.category}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        }

        final result = snapshot.data;
        if (result == null || result.listings.isEmpty) {
          return const SizedBox.shrink();
        }

        final String headerLabel = result.trendingTag != null
            ? 'More in ${listing.category} · ${result.trendingTag}'
            : 'More in ${listing.category}';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: result.listings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final rec = result.listings[i];
                    return SizedBox(
                      width: 160,
                      child: ListingCard(
                        listing: rec,
                        onTap: () =>
                            context.push('/listings/${rec.listingId}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
