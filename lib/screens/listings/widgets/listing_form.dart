import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/listing_model.dart';
import '../../../services/listing_service.dart';
import '../../../services/ai_service.dart';

class ListingFormResult {
  final String title;
  final double price;
  final String category;
  final String condition;
  final String description;
  final String location;
  final String imageBase64;

  ListingFormResult({
    required this.title,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.location,
    required this.imageBase64,
  });
}

class ListingForm extends StatefulWidget {
  final ListingModel? initial;
  final String submitLabel;
  final Future<void> Function(ListingFormResult result) onSubmit;

  const ListingForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ListingService _listingService = ListingService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _category = ListingCategory.others;
  String _condition = ListingCondition.lightlyUsed;
  String _imageBase64 = '';

  bool _isSubmitting = false;
  bool _isPickingImage = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _titleController.text = initial.title;
      _priceController.text = initial.price.toStringAsFixed(2);
      _descriptionController.text = initial.description;
      _locationController.text = initial.location;
      _category = ListingCategory.values.contains(initial.category)
          ? initial.category
          : ListingCategory.others;
      _condition = ListingCondition.values.contains(initial.condition)
          ? initial.condition
          : ListingCondition.lightlyUsed;
      _imageBase64 = initial.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
      _errorMessage = '';
    });
    try {
      final String? encoded =
          await _listingService.pickAndEncodeImage(source: source);
      if (encoded != null) {
        setState(() => _imageBase64 = encoded);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _generateAiDescription() {
    final title = _titleController.text.trim();
    final category = _category;
    final condition = _condition.toLowerCase();
    final priceStr = _priceController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Title first so the AI has context!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    final priceText = price > 0 ? 'for RM ${price.toStringAsFixed(2)}' : 'for a reasonable price';
    final locationText = location.isNotEmpty ? 'Available for pickup/meetup at $location.' : 'Available for meetup on campus.';

    String generated = '';

    if (category == ListingCategory.textbooks) {
      generated = 'Hey UTM students! Selling my textbook "$title". '
          'It is in $condition condition. Perfect resource for study references or courses this semester. '
          'Selling this $priceText. $locationText PM me if interested, open to discuss!';
    } else if (category == ListingCategory.electronics) {
      generated = 'Hi UTM! I\'m selling this electronic device: "$title" ($condition condition). '
          'It works perfectly and has been taken care of nicely. '
          'Letting it go $priceText. $locationText Great deal for students looking for reliable tech. PM me to negotiate or ask questions!';
    } else if (category == ListingCategory.clothing) {
      generated = 'Hi everyone! Selling this fashion piece: "$title". '
          'Condition is $condition. Super comfortable and looks great. '
          'Selling $priceText. $locationText Direct message me if you want to request more photos or measurements. Thank you!';
    } else if (category == ListingCategory.furniture) {
      generated = 'Hello UTM community! I have this furniture item: "$title" in $condition condition. '
          'Ideal for dorm rooms or student apartments nearby campus. '
          'Letting it go $priceText. $locationText You will need to arrange for self-pickup. Message me if you have any questions!';
    } else if (category == ListingCategory.sports) {
      generated = 'Hi guys! Selling my sports/outdoor gear: "$title" in $condition condition. '
          'Great for remaining active on campus! '
          'Selling $priceText. $locationText DM me if you want to inspect it or discuss transaction details.';
    } else if (category == ListingCategory.vehicles) {
      generated = 'UTM Marketplace! Selling vehicle/riding asset: "$title" ($condition condition). '
          'Perfect and reliable for campus commuting. '
          'Selling $priceText. $locationText Serious buyers only, please DM me for viewings or test rides!';
    } else if (category == ListingCategory.free) {
      generated = 'Giving away this item for FREE to any UTM student: "$title". '
          'Condition is $condition. '
          'Just letting it go to declutter. $locationText First come, first served. PM me to secure it!';
    } else {
      generated = 'Hey everyone! Selling "$title" in $condition condition. '
          'Great addition for campus student life. '
          'Offering this $priceText. $locationText Please contact me if you are interested or have any questions. Open to offers!';
    }

    setState(() {
      _descriptionController.text = generated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ AI Description generated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _generateDeepSeekDescription() async {
    final title = _titleController.text.trim();
    final category = _category;
    final condition = _condition;
    final priceStr = _priceController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Title first so the AI has context!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double price = double.tryParse(priceStr) ?? 0.0;

    if (AiService.deepSeekApiKey.trim().isEmpty) {
      final TextEditingController keyController = TextEditingController();
      final bool? saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('✨ Configure DeepSeek AI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your DeepSeek API Key to generate advanced, custom descriptions:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (keyController.text.trim().isNotEmpty) {
                  AiService.deepSeekApiKey = keyController.text.trim();
                  Navigator.of(ctx).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a key.')),
                  );
                }
              },
              child: const Text('Save & Generate'),
            ),
          ],
        ),
      );
      if (saved != true) return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Consulting DeepSeek AI...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final String result = await AiService.generateDescription(
        title: title,
        category: category,
        condition: condition,
        price: price,
        location: location,
      );

      if (mounted) Navigator.of(context).pop();

      setState(() {
        _descriptionController.text = result;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🤖 DeepSeek AI Description generated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('AI Generation Failed'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _suggestPrice() async {
    final title = _titleController.text.trim();
    final category = _category;
    final condition = _condition;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Title first to estimate pricing!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (AiService.deepSeekApiKey.trim().isNotEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calculating Price Suggestions (DeepSeek)...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final suggestion = await AiService.suggestPrice(
          title: title,
          category: category,
          condition: condition,
        );

        if (mounted) Navigator.of(context).pop();

        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🤖 DeepSeek Price Recommendation'),
            content: Text(suggestion),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showLocalPriceSuggestion(title, category, condition);
      }
    } else {
      _showLocalPriceSuggestion(title, category, condition);
    }
  }

  void _showLocalPriceSuggestion(String title, String category, String condition) {
    String suggestedRange = '';
    String tips = '';

    if (category == ListingCategory.textbooks) {
      suggestedRange = 'RM 20.00 - RM 40.00';
      tips = 'UTM textbook resale value generally sits around 50% of the retail price. Since the item is in "$condition" condition, pricing it around the middle will attract buyers fast!';
    } else if (category == ListingCategory.electronics) {
      suggestedRange = 'RM 100.00 - RM 450.00';
      tips = 'Electronics are highly sought-after. For a "$condition" item, we suggest keeping it within this range depending on product age and configuration.';
    } else if (category == ListingCategory.clothing) {
      suggestedRange = 'RM 15.00 - RM 30.00';
      tips = 'Clothing lists move fastest when priced cheaply. RM 20-RM 25 is ideal for students.';
    } else if (category == ListingCategory.furniture) {
      suggestedRange = 'RM 45.00 - RM 110.00';
      tips = 'Reselling furniture works best for items like study tables/chairs. For "$condition" condition, a price around RM 60 is standard.';
    } else if (category == ListingCategory.vehicles) {
      suggestedRange = 'RM 1,200.00 - RM 2,800.00';
      tips = 'Commute aids on campus. Prices vary highly depending on state registration, servicing history and tires.';
    } else if (category == ListingCategory.free) {
      suggestedRange = 'RM 0.00';
      tips = 'Generous choice! Giving items away for free is highly appreciated in the community.';
    } else {
      suggestedRange = 'RM 10.00 - RM 50.00';
      tips = 'For misc items, keeping prices low guarantees sales. Most buyers search for cheap, budget-friendly items.';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✨ Smart Price Recommender (Local)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: "$title"', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Category: $category'),
            Text('Condition: $condition'),
            const SizedBox(height: 12),
            const Text('Suggested Resale Range:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            Text(suggestedRange, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF89986D))),
            const SizedBox(height: 12),
            Text(tips, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_imageBase64.isEmpty) {
      setState(() => _errorMessage = 'Please add an image for the listing.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      await widget.onSubmit(
        ListingFormResult(
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _category,
          condition: _condition,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          imageBase64: _imageBase64,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? imageBytes = _decode(_imageBase64);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _isPickingImage ? null : _showImageSourceSheet,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _isPickingImage
                  ? const Center(child: CircularProgressIndicator())
                  : imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
            ),
          ),
          if (imageBytes != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _isPickingImage ? null : _showImageSourceSheet,
                icon: const Icon(Icons.refresh),
                label: const Text('Change photo'),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Please enter a title.';
              if (v.length < 3) return 'Title must be at least 3 characters.';
              if (v.length > 80) return 'Title must be under 80 characters.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price (RM)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              TextButton.icon(
                onPressed: _suggestPrice,
                icon: const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF89986D)),
                label: const Text(
                  'Suggest Price',
                  style: TextStyle(color: Color(0xFF89986D), fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              hintText: 'Enter price...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Please enter a price.';
              final parsed = double.tryParse(v);
              if (parsed == null) return 'Please enter a valid number.';
              if (parsed < 0) return 'Price cannot be negative.';
              if (parsed > 1000000) return 'Price is too high.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            items: ListingCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
            validator: (value) =>
                value == null ? 'Please choose a category.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _condition,
            decoration: const InputDecoration(
              labelText: 'Condition',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.star_border),
            ),
            items: ListingCondition.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _condition = value);
            },
            validator: (value) =>
                value == null ? 'Please choose a condition.' : null,
          ),
          Row(
            children: [
              Text(
                'Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _generateAiDescription,
                    icon: const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF89986D)),
                    label: const Text(
                      'Local AI',
                      style: TextStyle(color: Color(0xFF89986D), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _generateDeepSeekDescription,
                    icon: const Icon(Icons.psychology, size: 12, color: Color(0xFF89986D)),
                    label: const Text(
                      'Pro AI (DeepSeek)',
                      style: TextStyle(color: Color(0xFF89986D), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Write details about your item, or tap Local AI / Pro AI to auto-generate a description!',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Please enter a description.';
              if (v.length < 10) {
                return 'Description must be at least 10 characters.';
              }
              if (v.length > 1000) {
                return 'Description must be under 1000 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
              hintText: 'e.g. KTDI, Kolej Tun Razak',
            ),
            textInputAction: TextInputAction.done,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Please enter a location.';
              if (v.length > 100) return 'Location must be under 100 characters.';
              return null;
            },
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    widget.submitLabel,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
        ],
      ),
    );
  }
}
