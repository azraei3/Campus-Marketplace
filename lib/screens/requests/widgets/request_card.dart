import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/request_model.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final String personLabel;
  final String personName;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RequestCard({
    super.key,
    required this.request,
    required this.personLabel,
    required this.personName,
    this.onTap,
    this.trailing,
  });

  Uint8List? _decode(String url) {
    if (url.isEmpty) return null;
    try {
      return base64Decode(url);
    } on FormatException {
      return null;
    }
  }

  Color _statusColor() {
    switch (request.status) {
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
    final Uint8List? bytes = _decode(request.listingImage);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 70,
                      height: 70,
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.listingTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$personLabel: $personName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (request.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${request.message}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(height: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
