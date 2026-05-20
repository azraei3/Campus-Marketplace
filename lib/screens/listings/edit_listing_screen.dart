import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_model.dart';
import '../../services/listing_service.dart';
import 'widgets/listing_form.dart';

class EditListingScreen extends StatefulWidget {
  final String listingId;
  const EditListingScreen({super.key, required this.listingId});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final ListingService _listingService = ListingService();
  late Future<ListingModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _listingService.getListing(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: FutureBuilder<ListingModel?>(
        future: _future,
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
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
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

          if (listing.status != ListingStatus.available) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'This listing is ${listing.status} and cannot be edited.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListingForm(
            initial: listing,
            submitLabel: 'Update Listing',
            onSubmit: (result) async {
              await _listingService.updateListing(
                listingId: listing.listingId,
                title: result.title,
                price: result.price,
                category: result.category,
                condition: result.condition,
                description: result.description,
                location: result.location,
                imageBase64: result.imageBase64,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing updated!')),
                );
                context.pop();
              }
            },
          );
        },
      ),
    );
  }
}
