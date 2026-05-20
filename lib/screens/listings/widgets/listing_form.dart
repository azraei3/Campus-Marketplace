import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/listing_model.dart';
import '../../../services/listing_service.dart';

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
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price (RM)',
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
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
