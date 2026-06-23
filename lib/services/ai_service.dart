import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart' as keys;

class AiService {
  static String deepSeekApiKey = keys.deepSeekApiKey;

  static Future<String> generateDescription({
    required String title,
    required String category,
    required String condition,
    required double price,
    required String location,
  }) async {
    if (deepSeekApiKey.trim().isEmpty) {
      throw Exception('DeepSeek API Key is not set.');
    }

    final response = await http.post(
      Uri.parse('https://api.deepseek.com/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful campus assistant that writes engaging student marketplace descriptions for the UTM (University of Technology Malaysia) community. Keep descriptions friendly, informative, structured, and under 400 characters. Prompt potential buyers to contact via private chat.'
          },
          {
            'role': 'user',
            'content': 'Write a short description for an item with these details:\n'
                '- Title: $title\n'
                '- Category: $category\n'
                '- Condition: $condition\n'
                '- Price: RM ${price.toStringAsFixed(2)}\n'
                '- Location: $location'
          }
        ],
        'temperature': 0.7,
        'max_tokens': 150,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final text = body['choices'][0]['message']['content'] as String;
      return text.trim();
    } else {
      final err = jsonDecode(response.body);
      final msg = err['error']?['message'] ?? 'Unknown API error';
      throw Exception('DeepSeek API Error: $msg (Status: ${response.statusCode})');
    }
  }

  static Future<String> suggestPrice({
    required String title,
    required String category,
    required String condition,
  }) async {
    if (deepSeekApiKey.trim().isEmpty) {
      throw Exception('DeepSeek API Key is not set.');
    }

    final response = await http.post(
      Uri.parse('https://api.deepseek.com/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert pricing consultant for a student university marketplace. Based on the item details, recommend a reasonable selling price in Malaysian Ringgits (RM). Provide a short 2-sentence explanation with a suggested range.'
          },
          {
            'role': 'user',
            'content':
                'Recommend resale pricing for:\n- Title: $title\n- Category: $category\n- Condition: $condition'
          }
        ],
        'temperature': 0.7,
        'max_tokens': 120,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final text = body['choices'][0]['message']['content'] as String;
      return text.trim();
    } else {
      throw Exception(
          'Failed to estimate price (Status code: ${response.statusCode})');
    }
  }

  static Future<String> generateChatReply({
    required String listingTitle,
    required double price,
    required String lastMessage,
    required String replyType,
  }) async {
    if (deepSeekApiKey.trim().isEmpty) {
      throw Exception('DeepSeek API Key is not set.');
    }

    String promptContext = '';
    if (replyType == 'discount') {
      promptContext =
          'Draft a polite request asking the seller if they could offer a small discount on the item.';
    } else if (replyType == 'meetup') {
      promptContext =
          'Draft a friendly meetup confirmation, proposing to meet up at a common UTM college landmark (like KTDI, KTR, or KDOJ) to complete the transaction.';
    } else {
      promptContext =
          'Draft a polite response declining the transaction or offer.';
    }

    final response = await http.post(
      Uri.parse('https://api.deepseek.com/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful UTM university student. Draft a short, natural, friendly, 1-2 sentence chat reply message. Do not include subject lines or greetings like "Dear Seller". Write as a direct text message.'
          },
          {
            'role': 'user',
            'content': 'Item: $listingTitle priced at RM ${price.toStringAsFixed(2)}.\n'
                'Last message received: "$lastMessage"\n'
                'Goal: $promptContext'
          }
        ],
        'temperature': 0.7,
        'max_tokens': 100,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final text = body['choices'][0]['message']['content'] as String;
      final trimmed = text.trim();
      return (trimmed.startsWith('"') || trimmed.startsWith("'")) && trimmed.length > 1
          ? trimmed.substring(1, trimmed.length - 1)
          : trimmed;
    } else {
      throw Exception(
          'Failed to generate reply (Status code: ${response.statusCode})');
    }
  }
  // Safety Scanner
  /// Analyses a list of chat messages for potential scam signals or safety issues.
  /// Returns a map with keys: 'status' ('safe'|'warning'|'danger'), 'title', 'body'.
  static Future<Map<String, String>> analyzeChatSafety({
    required String listingTitle,
    required double price,
    required List<String> messages,
  }) async {
    final conversationText = messages.take(15).join('\n');

    if (deepSeekApiKey.trim().isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
          },
          body: jsonEncode({
            'model': 'deepseek-chat',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a campus marketplace safety AI for UTM (University of Technology Malaysia). '
                    'Analyse the chat conversation and detect if there are any scam or safety risk signals such as: '
                    'requests for advance bank transfers/deposits, requests to move to other platforms (WhatsApp, Telegram), '
                    'suspicious urgency, unrealistic pricing, refusal of in-person meetup on campus, or requests for personal sensitive info. '
                    'Respond ONLY in this exact JSON format with no extra text: '
                    '{"status":"safe"|"warning"|"danger","title":"short headline","body":"2-3 sentence analysis with specific findings and advice for the buyer."}'
              },
              {
                'role': 'user',
                'content':
                    'Item: "$listingTitle" at RM ${price.toStringAsFixed(2)}\nConversation:\n$conversationText'
              }
            ],
            'temperature': 0.3,
            'max_tokens': 200,
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final raw = body['choices'][0]['message']['content'] as String;
          // Strip markdown fences if present
          final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
          final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
          return {
            'status': parsed['status']?.toString() ?? 'safe',
            'title': parsed['title']?.toString() ?? 'Analysis Complete',
            'body': parsed['body']?.toString() ?? 'No issues detected.',
          };
        }
      } catch (_) {
        // fall through to local engine
      }
    }
    // Fallback safety engine
    return _localSafetyAnalysis(conversationText, listingTitle, price);
  }

  static Map<String, String> _localSafetyAnalysis(
      String conversation, String title, double price) {
    final lower = conversation.toLowerCase();

    final dangerSignals = [
      'transfer', 'bank account', 'payment first', 'deposit first',
      'pay first', 'send rm', 'online transfer', 'maya', 'tng ewallet',
    ];
    final warningSignals = [
      'whatsapp', 'telegram', 'call me', 'my number', 'outside campus',
      'urgent', 'last one', 'best price', 'discount only today',
    ];

    final foundDanger =
        dangerSignals.where((s) => lower.contains(s)).toList();
    final foundWarning =
        warningSignals.where((s) => lower.contains(s)).toList();

    if (foundDanger.isNotEmpty) {
      return {
        'status': 'danger',
        'title': '🚨 High Risk — Possible Scam Detected',
        'body':
            'This conversation contains high-risk signals: payment/transfer requests before meetup. '
            'Legitimate UTM sellers do NOT ask for advance payments. '
            'Always insist on a face-to-face exchange on campus (KTDI, KTR, KDOJ).',
      };
    } else if (foundWarning.isNotEmpty) {
      return {
        'status': 'warning',
        'title': '⚠️ Caution — Review Before Proceeding',
        'body':
            'Some caution signals were detected (e.g. off-platform contact requests or urgency). '
            'Stay on the Campus Marketplace chat and arrange to meet in a public, well-lit area on UTM campus. '
            'Do not share personal details externally.',
      };
    } else {
      return {
        'status': 'safe',
        'title': '✅ Conversation Looks Safe',
        'body':
            'No scam or safety signals detected in this conversation. '
            'The exchange appears to follow normal student marketplace behaviour. '
            'Remember to always complete your transaction in-person on UTM campus.',
      };
    }
  }
  // Review Generator
  /// Generates a polished, natural review comment based on star rating and selected tags.
  static Future<String> generateSellerReview({
    required int stars,
    required String sellerName,
    required String itemTitle,
    required List<String> tags,
  }) async {
    final tagLine = tags.isEmpty ? 'general' : tags.join(', ');

    if (deepSeekApiKey.trim().isNotEmpty) {
      try {
        final sentiment = stars >= 4
            ? 'positive and warm'
            : stars == 3
                ? 'neutral and constructive'
                : 'honest but polite and constructive';

        final response = await http.post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
          },
          body: jsonEncode({
            'model': 'deepseek-chat',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a UTM student writing a marketplace seller review. '
                    'Write a natural, genuine, 2-3 sentence review. Be $sentiment. '
                    'Do NOT use formal language or introductions. Write as a real student would text.'
              },
              {
                'role': 'user',
                'content':
                    'Write a $stars-star review for seller "$sellerName" for the item "$itemTitle". '
                    'Highlight these aspects: $tagLine.'
              }
            ],
            'temperature': 0.8,
            'max_tokens': 120,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final text = body['choices'][0]['message']['content'] as String;
          final cleaned2 = text.trim();
          if (cleaned2.startsWith('"') || cleaned2.startsWith("'")) {
            return cleaned2.substring(1, cleaned2.length - 1);
          }
          return cleaned2;
        }
      } catch (_) {
        // fall through to local
      }
    }
    // Fallback templates
    return _localReviewTemplate(stars, sellerName, itemTitle, tags);
  }

  static String _localReviewTemplate(
      int stars, String sellerName, String item, List<String> tags) {
    final tagStr =
        tags.isEmpty ? 'great seller' : tags.map((t) => t.toLowerCase()).join(', ');

    if (stars >= 5) {
      return 'Amazing experience buying "$item" from $sellerName! '
          'Seller was $tagStr — could not ask for a smoother transaction. '
          'Highly recommend to all UTM students, 10/10 would buy again! 🌟';
    } else if (stars == 4) {
      return 'Really happy with my purchase of "$item". '
          '$sellerName was $tagStr and the item was exactly as described. '
          'Would definitely deal with this seller again!';
    } else if (stars == 3) {
      return 'Decent transaction for "$item". '
          'Seller was okay overall — $tagStr. '
          'A few minor hiccups but nothing too serious. Alright deal!';
    } else if (stars == 2) {
      return 'Had a somewhat disappointing experience with "$item". '
          'Communication could be improved and the item condition did not fully match the listing. '
          'Hoped for better but it was manageable.';
    } else {
      return 'Unfortunately, this transaction for "$item" did not go as expected. '
          'The item was not as described and the seller was unresponsive. '
          'Would caution other buyers to be careful.';
    }
  }
  // Listing Deal Score
  /// Analyses a listing and returns a deal score map with keys:
  /// 'grade' (A+/A/B/C), 'label', 'reason', 'color' (hex string).
  static Future<Map<String, String>> analyzeDealScore({
    required String title,
    required String category,
    required String condition,
    required double price,
    required String description,
    required int saveCount,
    required int viewCount,
  }) async {
    if (deepSeekApiKey.trim().isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
          },
          body: jsonEncode({
            'model': 'deepseek-chat',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a student marketplace deal analyst for UTM (University of Technology Malaysia). '
                    'Evaluate whether a listed item is a great deal for university students. '
                    'Consider: is the price reasonable for the category and condition? '
                    'Is the description clear and trustworthy? How popular is it (saves/views)? '
                    'Respond ONLY in this exact JSON format with no extra text: '
                    '{"grade":"A+"|"A"|"B"|"C","label":"short 2-word label e.g. Great Deal","reason":"1-sentence plain explanation"}'
              },
              {
                'role': 'user',
                'content':
                    'Title: $title\nCategory: $category\nCondition: $condition\n'
                    'Price: RM ${price.toStringAsFixed(2)}\nDescription: $description\n'
                    'Saves: $saveCount, Views: $viewCount'
              }
            ],
            'temperature': 0.4,
            'max_tokens': 120,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final raw = body['choices'][0]['message']['content'] as String;
          final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
          final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
          final grade = parsed['grade']?.toString() ?? 'B';
          return {
            'grade': grade,
            'label': parsed['label']?.toString() ?? 'Fair Deal',
            'reason': parsed['reason']?.toString() ?? 'Reasonable listing.',
            'color': _gradeToColor(grade),
          };
        }
      } catch (_) {
        // fall through to local engine
      }
    }
    // Fallback scoring
    return _localDealScore(
        category: category,
        condition: condition,
        price: price,
        saveCount: saveCount,
        viewCount: viewCount);
  }

  static String _gradeToColor(String grade) {
    switch (grade) {
      case 'A+':
        return '#1B5E20';
      case 'A':
        return '#2E7D32';
      case 'B':
        return '#F57F17';
      default:
        return '#B71C1C';
    }
  }

  static Map<String, String> _localDealScore({
    required String category,
    required String condition,
    required double price,
    required int saveCount,
    required int viewCount,
  }) {
    // Rough fair-price ranges per category in RM
    final Map<String, double> fairPrices = {
      'Textbooks': 40,
      'Electronics': 200,
      'Clothing': 30,
      'Furniture': 80,
      'Sports': 50,
      'Vehicles': 800,
      'Free': 0,
      'Others': 60,
    };

    final double fair = fairPrices[category] ?? 60;
    final double ratio = fair > 0 ? price / fair : 0;

    // Condition modifier
    double conditionMod = 0;
    if (condition == 'Like New') conditionMod = -0.1;
    if (condition == 'Well Used') conditionMod = 0.15;
    final double adjusted = ratio + conditionMod;

    // Popularity boost
    final bool popular = saveCount >= 3 || viewCount >= 20;

    String grade;
    String label;
    String reason;
    if (price == 0) {
      grade = 'A+';
      label = 'FREE 🎁';
      reason = 'This item is free — an unbeatable deal for UTM students!';
    } else if (adjusted <= 0.65 && popular) {
      grade = 'A+';
      label = 'Steal Deal';
      reason =
          'Priced well below market average and trending with other buyers — grab it fast!';
    } else if (adjusted <= 0.75) {
      grade = 'A';
      label = 'Great Deal';
      reason =
          'Priced noticeably below market value for a $condition item. Good buy for students.';
    } else if (adjusted <= 1.1) {
      grade = 'B';
      label = 'Fair Price';
      reason =
          'Priced around the typical market rate for a $condition $category item at UTM.';
    } else {
      grade = 'C';
      label = 'High Price';
      reason =
          'Priced slightly above typical student market rates. Consider negotiating.';
    }

    return {
      'grade': grade,
      'label': label,
      'reason': reason,
      'color': _gradeToColor(grade),
    };
  }
  // Reputation Summary
  /// Reads a list of review comments and generates a Google Maps-style
  /// 2-sentence natural language summary of the seller.
  static Future<String> summarizeSellerReputation({
    required String sellerName,
    required double averageRating,
    required int totalRatings,
    required List<String> reviewComments,
  }) async {
    if (totalRatings == 0) {
      return '$sellerName is a new seller on Campus Marketplace with no reviews yet. '
          'Be the first to trade and leave a review!';
    }

    final commentText = reviewComments
        .where((c) => c.trim().isNotEmpty)
        .take(10)
        .join(' | ');

    if (deepSeekApiKey.trim().isNotEmpty && commentText.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
          },
          body: jsonEncode({
            'model': 'deepseek-chat',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that generates concise seller reputation summaries for a university campus marketplace. '
                    'Write exactly 2 short sentences summarizing what buyers think of this seller. '
                    'Be factual, friendly, and specific. Reference common themes from the reviews. '
                    'Do NOT use bullet points or lists. Write in a tone similar to Google Maps AI review summaries.'
              },
              {
                'role': 'user',
                'content':
                    'Seller: $sellerName | Average: ${averageRating.toStringAsFixed(1)}/5 stars | '
                    'Total reviews: $totalRatings\nReviews: $commentText'
              }
            ],
            'temperature': 0.5,
            'max_tokens': 120,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final text = body['choices'][0]['message']['content'] as String;
          return text.trim();
        }
      } catch (_) {
        // fall through to local
      }
    }
    // Fallback templates
    return _localReputationSummary(
        sellerName: sellerName,
        averageRating: averageRating,
        totalRatings: totalRatings);
  }

  static String _localReputationSummary({
    required String sellerName,
    required double averageRating,
    required int totalRatings,
  }) {
    final String ratingWord = averageRating >= 4.5
        ? 'exceptional'
        : averageRating >= 4.0
            ? 'great'
            : averageRating >= 3.0
                ? 'decent'
                : 'mixed';

    final String reviewPlural =
        totalRatings == 1 ? '1 review' : '$totalRatings reviews';

    if (averageRating >= 4.5) {
      return '$sellerName is one of the top-rated sellers on Campus Marketplace, '
          'earning $ratingWord feedback across $reviewPlural. '
          'Buyers consistently praise their reliability and item quality.';
    } else if (averageRating >= 4.0) {
      return '$sellerName has built a solid reputation with $ratingWord ratings from $reviewPlural. '
          'Most buyers report a smooth, trustworthy trading experience.';
    } else if (averageRating >= 3.0) {
      return '$sellerName has received $ratingWord feedback from $reviewPlural. '
          'Buyers suggest verifying item details before purchasing.';
    } else {
      return '$sellerName has received mixed reviews from $reviewPlural. '
          'Exercise caution and clarify item condition before proceeding.';
    }
  }
  // RAG Chatbot
  /// Answers a natural-language question about the live marketplace by
  /// passing real listing + seller + review data as context to DeepSeek.
  ///
  /// [listings] — live available listings
  /// [sellers]  — map of sellerId → { name, averageRating, totalRatings, isVerified }
  /// [reviews]  — list of { sellerName, reviewerName, score, comment }
  static Future<String> askMarketplaceAssistant({
    required String question,
    required List<Map<String, dynamic>> listings,
    List<Map<String, dynamic>> sellers = const [],
    List<Map<String, dynamic>> reviews = const [],
  }) async {
    // Listings context
    final listingCtx = listings.take(25).map((l) {
      final verified = l['sellerIsVerified'] == true ? ' ✓verified' : '';
      return '• ${l['title']} | ${l['category']} | ${l['condition']} | '
          'RM${(l['price'] as num).toStringAsFixed(0)} | '
          'Seller: ${l['sellerName']}$verified | '
          'Location: ${l['location'] ?? 'UTM'}';
    }).join('\n');
    // Seller profiles context
    final sellerCtx = sellers.isEmpty
        ? ''
        : '\n\nSELLER PROFILES & RATINGS:\n${sellers.map((s) {
              final avg = (s['averageRating'] as num?)?.toStringAsFixed(1) ?? '0.0';
              final total = s['totalRatings'] ?? 0;
              final verified = s['isVerified'] == true ? ' ✓verified' : '';
              return '• ${s['name']}$verified — ⭐ $avg/5 ($total reviews)';
            }).join('\n')}';
    // Recent reviews context
    final reviewCtx = reviews.isEmpty
        ? ''
        : '\n\nRECENT BUYER REVIEWS:\n${reviews.take(15).map((r) {
              return '• ${r['sellerName']} got ${r['score']}/5 from ${r['reviewerName']}: "${r['comment']}"';
            }).join('\n')}';

    final fullContext = 'LIVE LISTINGS:\n$listingCtx$sellerCtx$reviewCtx';

    if (deepSeekApiKey.trim().isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${deepSeekApiKey.trim()}',
          },
          body: jsonEncode({
            'model': 'deepseek-chat',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a helpful AI assistant for the Campus Marketplace app at UTM '
                    '(University of Technology Malaysia). You help students find items, '
                    'compare prices, check seller trustworthiness, and make smart buying decisions. '
                    'You have full access to live listings, seller ratings, and buyer reviews. '
                    'Answer naturally and helpfully in 2-4 sentences. Be friendly and specific. '
                    'Always reference actual items, prices, and seller names from the data.\n\n'
                    '$fullContext'
              },
              {
                'role': 'user',
                'content': question,
              }
            ],
            'temperature': 0.6,
            'max_tokens': 220,
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          return (body['choices'][0]['message']['content'] as String).trim();
        }
      } catch (_) {
        // fall through to local
      }
    }
    // Fallback search
    return _localAssistantAnswer(question: question, listings: listings,
        sellers: sellers);

  }

  static String _localAssistantAnswer({
    required String question,
    required List<Map<String, dynamic>> listings,
    List<Map<String, dynamic>> sellers = const [],
  }) {
    final q = question.toLowerCase();

    // Seller ratings query
    if (q.contains('rating') || q.contains('rated') || q.contains('review') ||
        q.contains('trusted') || q.contains('reliable') || q.contains('good seller')) {
      if (sellers.isNotEmpty) {
        final sorted = [...sellers]
          ..sort((a, b) =>
              (b['averageRating'] as num? ?? 0)
                  .compareTo(a['averageRating'] as num? ?? 0));
        final top = sorted.take(3);
        final desc = top.map((s) {
          final avg = (s['averageRating'] as num?)?.toStringAsFixed(1) ?? '?';
          return '${s['name']} (⭐$avg)';
        }).join(', ');
        return 'The top-rated sellers right now are: $desc. '
            'Tap on any seller\'s name on a listing to view their full profile and reviews!';
      }
    }

    // Cheapest item
    if (q.contains('cheap') || q.contains('lowest price') || q.contains('affordable')) {
      final sorted = [...listings]
        ..sort((a, b) =>
            (a['price'] as num).compareTo(b['price'] as num));
      if (sorted.isNotEmpty) {
        final item = sorted.first;
        return 'The most affordable item right now is "${item['title']}" '
            'by ${item['sellerName']} at only RM${(item['price'] as num).toStringAsFixed(0)}. '
            'That\'s a great deal for UTM students!';
      }
    }

    // Category filter
    for (final cat in ['textbooks', 'electronics', 'clothing', 'furniture', 'sports', 'vehicles']) {
      if (q.contains(cat) || q.contains(cat.substring(0, cat.length - 1))) {
        final catItems = listings
            .where((l) => (l['category'] as String).toLowerCase().contains(cat.substring(0, 4)))
            .toList();
        if (catItems.isNotEmpty) {
          final names = catItems.take(3).map((l) => '"${l['title']}" at RM${(l['price'] as num).toStringAsFixed(0)}').join(', ');
          return 'I found ${catItems.length} ${cat.toUpperCase()} listing${catItems.length > 1 ? 's' : ''} available: $names. '
              'Tap any listing card for full details and to contact the seller!';
        }
        return 'There are no $cat listings available right now. Check back soon or browse other categories!';
      }
    }

    // Verified sellers
    if (q.contains('verified') || q.contains('safe seller')) {
      final verified = listings.where((l) => l['sellerIsVerified'] == true).toList();
      if (verified.isNotEmpty) {
        final names = verified.take(3).map((l) => '${l['sellerName']}').toSet().join(', ');
        return 'There are ${verified.length} listings from verified UTM sellers right now. '
            'Trusted sellers include: $names. Look for the blue ✓ badge on listings!';
      }
      return 'Enable "Verified sellers only" toggle on the home screen to filter for trusted accounts only.';
    }

    // Count / total
    if (q.contains('how many') || q.contains('total') || q.contains('available')) {
      return 'There are currently ${listings.length} item${listings.length == 1 ? '' : 's'} available on Campus Marketplace. '
          'Use the category chips at the top to filter by type, or search by keyword!';
    }

    // Default
    return 'I found ${listings.length} listings on Campus Marketplace right now. '
        'You can ask me things like "Who has the highest ratings?", "What\'s cheapest?", '
        'or "Show me electronics" and I\'ll answer using live data!';
  }
}
