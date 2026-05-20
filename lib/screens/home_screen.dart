import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/listing_model.dart';
import '../services/listing_service.dart';
import 'drawer_items.dart';
import 'listings/widgets/listing_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategory;
  String _searchQuery = '';
  bool _verifiedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ListingModel> _applyFilters(List<ListingModel> listings) {
    Iterable<ListingModel> filtered = listings;
    if (_verifiedOnly) {
      filtered = filtered.where((l) => l.sellerIsVerified);
    }
    if (_searchQuery.trim().isNotEmpty) {
      final String q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((l) =>
          l.title.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q) ||
          l.location.toLowerCase().contains(q));
    }
    return filtered.toList();
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chats',
            onPressed: () => context.push('/chats'),
          ),
        ],
      ),
      drawer: const Drawer(child: DrawerItems()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listings/create'),
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items, locations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildCategoryChip(null, 'All'),
                ...ListingCategory.values.map(
                  (c) => _buildCategoryChip(c, c),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Verified sellers only',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Switch(
                  value: _verifiedOnly,
                  onChanged: (v) => setState(() => _verifiedOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ListingModel>>(
              stream: _listingService.streamAvailableListings(
                category: _selectedCategory,
              ),
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
                            'Error loading listings: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final all = snapshot.data ?? <ListingModel>[];
                final listings = _applyFilters(all);

                if (listings.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty ||
                                          _selectedCategory != null ||
                                          _verifiedOnly
                                      ? 'No listings match your filters.'
                                      : 'No listings yet. Be the first to sell!',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return ListingCard(
                        listing: listing,
                        onTap: () => context.push(
                          '/listings/${listing.listingId}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? value, String label) {
    final bool selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _selectedCategory = value);
        },
      ),
    );
  }
}
