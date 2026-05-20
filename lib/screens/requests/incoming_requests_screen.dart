import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/rating_model.dart';
import '../../models/request_model.dart';
import '../../services/rating_service.dart';
import '../../services/request_service.dart';
import '../widgets/star_rating.dart';
import 'widgets/request_card.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  final RequestService _requestService = RequestService();
  final RatingService _ratingService = RatingService();
  String? _filter;

  Future<void> _showActionSheet(RequestModel request) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (request.status == RequestStatus.pending) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Accept request'),
                subtitle:
                    const Text('Listing will be marked as reserved.'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _respondToRequest(request, accept: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Reject request'),
                subtitle: const Text('Listing remains available.'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _respondToRequest(request, accept: false);
                },
              ),
            ] else if (request.status == RequestStatus.accepted) ...[
              ListTile(
                leading: const Icon(Icons.task_alt, color: Colors.green),
                title: const Text('Mark as completed'),
                subtitle: const Text(
                  'Listing will be marked as sold.',
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _completeRequest(request);
                },
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No actions available for this request.'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToRequest(
    RequestModel request, {
    required bool accept,
  }) async {
    final TextEditingController controller = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accept ? 'Accept request' : 'Reject request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              accept
                  ? 'Accepting will reserve this listing for ${request.buyerName}.'
                  : 'Rejecting will keep this listing available to others.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Optional message',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: accept ? Colors.green : Colors.red,
            ),
            child: Text(accept ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (accept) {
        await _requestService.acceptRequest(
          requestId: request.requestId,
          responseMessage: controller.text.trim(),
        );
      } else {
        await _requestService.rejectRequest(
          requestId: request.requestId,
          responseMessage: controller.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Request accepted' : 'Request rejected'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _completeRequest(RequestModel request) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as completed?'),
        content: const Text(
          'This will mark the listing as sold. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _requestService.completeRequest(requestId: request.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request marked as completed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Requests')),
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
              stream:
                  _requestService.streamIncomingRequests(status: _filter),
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
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter == null
                              ? 'No incoming requests yet.'
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
                    final bool actionable =
                        r.status == RequestStatus.pending ||
                            r.status == RequestStatus.accepted;
                    Widget? trailing;
                    if (actionable) {
                      trailing = Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showActionSheet(r),
                            icon: const Icon(Icons.settings, size: 16),
                            label: Text(
                              r.status == RequestStatus.pending
                                  ? 'Respond'
                                  : 'Complete',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else if (r.status == RequestStatus.completed) {
                      trailing = FutureBuilder<RatingModel?>(
                        future:
                            _ratingService.getRatingForRequest(r.requestId),
                        builder: (context, ratingSnap) {
                          final existing = ratingSnap.data;
                          if (existing == null) {
                            return const Text(
                              'Awaiting buyer rating',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            );
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              StarRating(
                                value: existing.score.toDouble(),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Buyer rating',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    return RequestCard(
                      request: r,
                      personLabel: 'From',
                      personName: r.buyerName,
                      onTap: () =>
                          context.push('/requests/${r.requestId}'),
                      trailing: trailing,
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
