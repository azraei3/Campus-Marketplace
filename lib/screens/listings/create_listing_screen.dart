import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/listing_service.dart';
import 'widgets/listing_form.dart';

class CreateListingScreen extends StatelessWidget {
  CreateListingScreen({super.key});

  final ListingService _listingService = ListingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell an Item')),
      body: ListingForm(
        submitLabel: 'Publish Listing',
        onSubmit: (result) async {
          await _listingService.createListing(
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
              const SnackBar(content: Text('Listing published!')),
            );
            context.pop();
          }
        },
      ),
    );
  }
}
