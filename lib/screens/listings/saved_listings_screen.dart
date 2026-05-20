import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_model.dart';
import '../../services/listing_service.dart';
import 'widgets/listing_card.dart';

class SavedListingsScreen extends StatefulWidget {
  const SavedListingsScreen({super.key});

  @override
  State<SavedListingsScreen> createState() => _SavedListingsScreenState();
}

class _SavedListingsScreenState extends State<SavedListingsScreen> {
  final ListingService _listingService = ListingService();

  Future<void> _unsave(String listingId) async {
    try {
      await _listingService.toggleSaved(listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _unavailableCard(String listingId) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Container(
            color: Colors.grey.shade200,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_circle_outline,
                      size: 36, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  const Text(
                    'This item is no longer available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _unsave(listingId),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text('Remove', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: StreamBuilder<List<String>>(
        stream: _listingService.streamSavedListingIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ids = snapshot.data ?? <String>[];

          if (ids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No saved items yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<ListingModel?>>(
            future: Future.wait(
              ids.map((id) => _listingService.getListing(id)),
            ),
            builder: (context, listingSnapshot) {
              if (listingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (listingSnapshot.hasError) {
                return Center(child: Text('Error: ${listingSnapshot.error}'));
              }

              final results = listingSnapshot.data ?? <ListingModel?>[];

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: ids.length,
                itemBuilder: (context, index) {
                  final listing = index < results.length ? results[index] : null;
                  final id = ids[index];
                  if (listing == null) {
                    return _unavailableCard(id);
                  }
                  return ListingCard(
                    listing: listing,
                    onTap: () => context.push('/listings/${listing.listingId}'),
                    trailing: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _unsave(listing.listingId),
                        icon: const Icon(Icons.heart_broken, size: 14),
                        label: const Text(
                          'Remove',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
