import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/request_model.dart';
import '../../services/ai_service.dart';
import '../../services/rating_service.dart';
import '../../services/request_service.dart';
import '../widgets/star_rating.dart';

class SubmitRatingScreen extends StatefulWidget {
  final String requestId;
  const SubmitRatingScreen({super.key, required this.requestId});

  @override
  State<SubmitRatingScreen> createState() => _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends State<SubmitRatingScreen>
    with SingleTickerProviderStateMixin {
  final RequestService _requestService = RequestService();
  final RatingService _ratingService = RatingService();
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late Future<RequestModel?> _future;
  int _score = 0;
  bool _isSubmitting = false;
  bool _isGeneratingReview = false;
  String _errorMessage = '';
  final Set<String> _selectedTags = {};

  // Tags split by sentiment
  static const List<Map<String, String>> _positiveTags = [
    {'label': 'Friendly 😊', 'key': 'Friendly'},
    {'label': 'On Time ⏰', 'key': 'On Time'},
    {'label': 'As Described 📦', 'key': 'As Described'},
    {'label': 'Good Price 💰', 'key': 'Good Price'},
    {'label': 'Fast Reply ⚡', 'key': 'Fast Reply'},
    {'label': 'Great Condition ✨', 'key': 'Great Condition'},
  ];
  static const List<Map<String, String>> _negativeTags = [
    {'label': 'Slow Reply 🐢', 'key': 'Slow Reply'},
    {'label': 'Late Meetup ⏳', 'key': 'Late Meetup'},
    {'label': 'Not As Described ⚠️', 'key': 'Not As Described'},
    {'label': 'Overpriced 💸', 'key': 'Overpriced'},
  ];

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
  // AI review writer
  Future<void> _generateAIReview(RequestModel request) async {
    if (_score == 0) {
      setState(() => _errorMessage = 'Please choose a star rating first.');
      return;
    }
    setState(() {
      _isGeneratingReview = true;
      _errorMessage = '';
    });

    try {
      final sellerName =
          request.sellerId.isNotEmpty ? 'the seller' : 'the seller';
      final tags = _selectedTags.isEmpty
          ? (_score >= 4 ? ['Friendly', 'As Described'] : ['Okay'])
          : _selectedTags.toList();

      final review = await AiService.generateSellerReview(
        stars: _score,
        sellerName: sellerName,
        itemTitle: request.listingTitle,
        tags: tags,
      );

      if (!mounted) return;
      setState(() {
        _commentController.text = review;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('AI review generated! Feel free to edit it.'),
            ],
          ),
          backgroundColor: const Color(0xFF7B3FE4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'AI generation failed: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingReview = false);
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
                // Item card
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

                // Star rating
                const Text(
                  'How would you rate this transaction?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Center(
                  child: StarRating(
                    value: _score.toDouble(),
                    size: 40,
                    onChanged: (v) {
                      setState(() {
                        _score = v;
                        _selectedTags.clear(); // reset tags when stars change
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),
                // Tag selection
                _buildTagSection(),

                const SizedBox(height: 20),

                // Comment field with AI generate button header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Review',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // AI Generate button
                    _isGeneratingReview
                        ? const SizedBox(
                            width: 120,
                            height: 34,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _generateAIReview(request),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7B3FE4),
                                    Color(0xFFB06AF5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7B3FE4)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 5),
                                  Text(
                                    'AI Write',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your experience... or tap AI Write ✨',
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

  Widget _buildTagSection() {



    if (_score == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select tags that apply',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_border, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Text(
                  'Select a star rating to see tags',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Decide positive vs negative based on stars
    final List<Map<String, String>> activeTags;
    if (_score >= 4) {
      activeTags = _positiveTags;
    } else if (_score == 3) {
      activeTags = [..._positiveTags, ..._negativeTags];
    } else {
      activeTags = _negativeTags;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tag this experience',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _score >= 4
                      ? [const Color(0xFF43A047), const Color(0xFF1B5E20)]
                      : _score == 3
                          ? [
                              const Color(0xFFF57F17),
                              const Color(0xFFE65100)
                            ]
                          : [
                              const Color(0xFFE53935),
                              const Color(0xFFB71C1C)
                            ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _score >= 4
                    ? 'Positive'
                    : _score == 3
                        ? 'Mixed'
                        : 'Negative',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick all that apply — AI will use these to generate your review',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeTags.map((tag) {
            final key = tag['key']!;
            final label = tag['label']!;
            final selected = _selectedTags.contains(key);

            final Color tagColor = _score >= 4
                ? const Color(0xFF2E7D32)
                : _score == 3
                    ? const Color(0xFFF57F17)
                    : const Color(0xFFE53935);

            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedTags.remove(key);
                } else {
                  _selectedTags.add(key);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? tagColor.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? tagColor
                        : Colors.grey.shade300,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected ? tagColor : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_selectedTags.length} tag${_selectedTags.length > 1 ? 's' : ''} selected → tap "AI Write" to generate review',
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7B3FE4),
                fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
