import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/request_model.dart';
import '../../services/request_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final RequestService _requestService = RequestService();
  late Future<RequestModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _requestService.getRequest(widget.requestId);
  }

  void _reload() {
    setState(() {
      _future = _requestService.getRequest(widget.requestId);
    });
  }

  Uint8List? _decode(String url) {
    if (url.isEmpty) return null;
    try {
      return base64Decode(url);
    } on FormatException {
      return null;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: FutureBuilder<RequestModel?>(
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
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final request = snapshot.data;
          if (request == null) {
            return const Center(
              child: Text('This request no longer exists.'),
            );
          }

          final bool isBuyer = currentUid == request.buyerId;
          final bool isSeller = currentUid == request.sellerId;
          final Uint8List? bytes = _decode(request.listingImage);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        context.push('/listings/${request.listingId}'),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: bytes != null
                              ? Image.memory(bytes, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  request.listingTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'View listing →',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'STATUS: ${request.status.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow('Buyer', request.buyerName),
                _infoRow('Sent at',
                    request.createdAt?.toLocal().toString() ?? '-'),
                if (request.updatedAt != null &&
                    request.updatedAt != request.createdAt)
                  _infoRow('Updated at',
                      request.updatedAt!.toLocal().toString()),
                const SizedBox(height: 16),
                const Text(
                  'Message',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  request.message.isEmpty
                      ? 'No message provided.'
                      : request.message,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                if (isSeller) _buildSellerActions(request),
                if (isBuyer)
                  Text(
                    _buyerStatusHint(request.status),
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _buyerStatusHint(String status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Waiting for the seller to respond.';
      case RequestStatus.accepted:
        return 'Your request was accepted. The seller will arrange the handover.';
      case RequestStatus.rejected:
        return 'Your request was rejected.';
      case RequestStatus.completed:
        return 'Purchase completed. Thank you!';
      default:
        return '';
    }
  }

  Widget _buildSellerActions(RequestModel request) {
    if (request.status == RequestStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _respond(request, accept: true),
              icon: const Icon(Icons.check_circle),
              label: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _respond(request, accept: false),
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text(
                'Reject',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      );
    }
    if (request.status == RequestStatus.accepted) {
      return ElevatedButton.icon(
        onPressed: () => _complete(request),
        icon: const Icon(Icons.task_alt),
        label: const Text('Mark as completed'),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _respond(RequestModel request, {required bool accept}) async {
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
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _complete(RequestModel request) async {
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
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
