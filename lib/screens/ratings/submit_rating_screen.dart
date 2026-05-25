import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/request_model.dart';
import '../../services/rating_service.dart';
import '../../services/request_service.dart';
import '../widgets/star_rating.dart';

class SubmitRatingScreen extends StatefulWidget {
  final String requestId;
  const SubmitRatingScreen({super.key, required this.requestId});

  @override
  State<SubmitRatingScreen> createState() => _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends State<SubmitRatingScreen> {
  final RequestService _requestService = RequestService();
  final RatingService _ratingService = RatingService();
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late Future<RequestModel?> _future;
  int _score = 0;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _future = _requestService.getRequest(widget.requestId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Uint8List? _decode(String url) {
    if (url.isEmpty) return null;
    try {
      return base64Decode(url);
    } on FormatException {
      return null;
    }
  }

  Future<void> _submit(RequestModel request) async {
    if (_score == 0) {
      setState(() => _errorMessage = 'Please choose a star rating.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      await _ratingService.submitRating(
        sellerId: request.sellerId,
        listingId: request.listingId,
        requestId: request.requestId,
        score: _score,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted. Thanks!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Seller')),
      body: FutureBuilder<RequestModel?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final request = snap.data;
          if (request == null) {
            return const Center(child: Text('Request not found.'));
          }
          if (request.status != RequestStatus.completed) {
            return const Center(
              child: Text('You can only rate completed transactions.'),
            );
          }

          final bytes = _decode(request.listingImage);

          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
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
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Seller: ${request.buyerId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'How would you rate this transaction?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Center(
                  child: StarRating(
                    value: _score.toDouble(),
                    size: 40,
                    onChanged: (v) => setState(() => _score = v),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional, 200 chars)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 200,
                  validator: (value) {
                    if ((value?.length ?? 0) > 200) {
                      return 'Comment must be under 200 characters.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () => _submit(request),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Submit Rating',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
