import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/rating_model.dart';
import '../../models/request_model.dart';
import '../../services/rating_service.dart';
import '../../services/request_service.dart';
import '../widgets/star_rating.dart';
import 'widgets/request_card.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final RequestService _requestService = RequestService();
  final RatingService _ratingService = RatingService();
  String? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _filterChip(null, 'All'),
                _filterChip(RequestStatus.pending, 'Pending'),
                _filterChip(RequestStatus.accepted, 'Accepted'),
                _filterChip(RequestStatus.rejected, 'Rejected'),
                _filterChip(RequestStatus.completed, 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: _requestService.streamMyRequests(status: _filter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final requests = snapshot.data ?? <RequestModel>[];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.outbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter == null
                              ? "You haven't sent any requests yet."
                              : 'No $_filter requests.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final r = requests[index];
                    return RequestCard(
                      request: r,
                      personLabel: 'Listing',
                      personName: r.listingTitle,
                      onTap: () =>
                          context.push('/requests/${r.requestId}'),
                      trailing: r.status == RequestStatus.completed
                          ? FutureBuilder<RatingModel?>(
                              future: _ratingService
                                  .getRatingForRequest(r.requestId),
                              builder: (context, ratingSnap) {
                                if (ratingSnap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 32,
                                    child: Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final existing = ratingSnap.data;
                                if (existing != null) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      StarRating(
                                        value: existing.score.toDouble(),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Your rating',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => context.push(
                                        '/requests/${r.requestId}/rate',
                                      ),
                                      icon: const Icon(Icons.star, size: 16),
                                      label: const Text('Rate Seller'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final bool selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
