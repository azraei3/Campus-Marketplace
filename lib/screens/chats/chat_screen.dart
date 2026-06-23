import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/ai_service.dart';
import '../../services/chat_service.dart';
import '../../services/listing_service.dart';
import '../../services/user_service.dart';
import '../widgets/verified_badge.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  // Scanner state
  bool _isScanning = false;
  Map<String, String>? _safetyResult;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(chatId: widget.chatId, text: text);
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
  // Chat Safety Analysis
  Future<void> _runSafetyScan(ChatModel chat) async {
    setState(() {
      _isScanning = true;
      _safetyResult = null;
    });

    double price = 0.0;
    try {
      final listing = await ListingService().getListing(chat.listingId);
      if (listing != null) price = listing.price;
    } catch (_) {}

    List<String> messages = [];
    try {
      final recent =
          await _chatService.getRecentMessages(widget.chatId, limit: 15);
      messages = recent.map((m) => m.text).toList();
    } catch (_) {
      messages = chat.lastMessage.isNotEmpty ? [chat.lastMessage] : [];
    }

    try {
      final result = await AiService.analyzeChatSafety(
        listingTitle: chat.listingTitle,
        price: price,
        messages: messages,
      );
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _safetyResult = result;
      });
      _showSafetyResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Safety scan failed: $e')),
      );
    }
  }

  void _showSafetyResultDialog(Map<String, String> result) {
    final status = result['status'] ?? 'safe';
    final title = result['title'] ?? 'Analysis Complete';
    final body = result['body'] ?? '';

    Color primaryColor;
    Color bgColor;
    Color borderColor;
    IconData iconData;
    List<Color> gradientColors;

    switch (status) {
      case 'danger':
        primaryColor = const Color(0xFFE53935);
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFEF9A9A);
        iconData = Icons.gpp_bad_rounded;
        gradientColors = [const Color(0xFFE53935), const Color(0xFFB71C1C)];
        break;
      case 'warning':
        primaryColor = const Color(0xFFF57F17);
        bgColor = const Color(0xFFFFFDE7);
        borderColor = const Color(0xFFFFE082);
        iconData = Icons.gpp_maybe_rounded;
        gradientColors = [const Color(0xFFF57F17), const Color(0xFFE65100)];
        break;
      default: // safe
        primaryColor = const Color(0xFF2E7D32);
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFFA5D6A7);
        iconData = Icons.verified_user_rounded;
        gradientColors = [const Color(0xFF43A047), const Color(0xFF1B5E20)];
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI Safety Scan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Container(
              color: bgColor,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      body,
                      style: TextStyle(
                        color: primaryColor.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tips row
                  if (status != 'safe')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tips_and_updates_outlined,
                              color: primaryColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tip: Always trade in-person at UTM campus landmarks. Never send money first.',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Got it',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: StreamBuilder<ChatModel?>(
        stream: _chatService.streamChat(widget.chatId),
        builder: (context, chatSnap) {
          if (chatSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatSnap.hasError) {
            return Center(child: Text('Error: ${chatSnap.error}'));
          }
          final chat = chatSnap.data;
          if (chat == null) {
            return const Center(child: Text('Chat not found.'));
          }
          final otherUid =
              currentUid != null ? chat.otherParticipant(currentUid) : '';

          return Column(
            children: [
              _buildHeader(context, chat, otherUid),
              // Safety banner (if scan was run)
              if (_safetyResult != null) _buildSafetyBanner(_safetyResult!),
              const Divider(height: 1),
              Expanded(child: _buildMessages(currentUid)),
              SafeArea(
                top: false,
                child: _buildComposer(chat),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSafetyBanner(Map<String, String> result) {
    final status = result['status'] ?? 'safe';
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case 'danger':
        bg = const Color(0xFFFFCDD2);
        fg = const Color(0xFFB71C1C);
        icon = Icons.gpp_bad_rounded;
        break;
      case 'warning':
        bg = const Color(0xFFFFF9C4);
        fg = const Color(0xFFE65100);
        icon = Icons.gpp_maybe_rounded;
        break;
      default:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.verified_user_rounded;
    }
    return InkWell(
      onTap: () => _showSafetyResultDialog(result),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: bg,
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result['title'] ?? '',
                style: TextStyle(
                    color: fg, fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Tap for details',
              style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatModel chat, String otherUid) {
    final bytes = _decode(chat.listingImage);
    return InkWell(
      onTap: () => context.push('/listings/${chat.listingId}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chat.listingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  StreamBuilder<UserModel?>(
                    stream: _userService.streamUser(otherUid),
                    builder: (context, snap) {
                      final other = snap.data;
                      return Row(
                        children: [
                          Flexible(
                            child: Text(
                              other?.name ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (other?.isVerified == true) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(size: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Safety trigger button
            _isScanning
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Tooltip(
                    message: 'AI Safety Scan',
                    child: InkWell(
                      onTap: () => _runSafetyScan(
                          // We need the ChatModel here; use streamChat.first
                          ChatModel(
                            chatId: widget.chatId,
                            listingId: '',
                            listingTitle: '',
                            listingImage: '',
                            participants: const [],
                            buyerId: '',
                            sellerId: '',
                            lastMessage: '',
                          )),
                      borderRadius: BorderRadius.circular(20),
                      child: StreamBuilder<ChatModel?>(
                        stream: _chatService.streamChat(widget.chatId),
                        builder: (ctx, snap) {
                          final c = snap.data;
                          return Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF43A047),
                                  Color(0xFF1B5E20),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: GestureDetector(
                              onTap: c != null ? () => _runSafetyScan(c) : null,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.security_rounded,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI Scan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(String? currentUid) {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.streamMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final messages = snapshot.data ?? <MessageModel>[];
        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet. Say hi!',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final m = messages[i];
            final bool mine = currentUid != null && m.senderId == currentUid;
            return _bubble(m, mine);
          },
        );
      },
    );
  }

  Widget _bubble(MessageModel m, bool mine) {
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = mine
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade200;
    final fg = mine ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(mine ? 12 : 2),
                  bottomRight: Radius.circular(mine ? 2 : 12),
                ),
              ),
              child: Text(
                m.text,
                style: TextStyle(color: fg, fontSize: 14),
              ),
            ),
          ),
          if (m.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _formatTimestamp(m.createdAt!),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _generateChatReply(ChatModel chat, String replyType) async {
    final lastMessage =
        chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Hello!';
    double price = 0.0;
    try {
      final listing = await ListingService().getListing(chat.listingId);
      if (listing != null) {
        price = listing.price;
      }
    } catch (_) {}

    if (!mounted) return;
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
                  Text('Drafting AI Reply (DeepSeek)...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final reply = await AiService.generateChatReply(
          listingTitle: chat.listingTitle,
          price: price,
          lastMessage: lastMessage,
          replyType: replyType,
        );

        if (mounted) Navigator.of(context).pop();

        setState(() {
          _messageController.text = reply;
        });
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showLocalChatReply(chat.listingTitle, price, replyType);
      }
    } else {
      _showLocalChatReply(chat.listingTitle, price, replyType);
    }
  }

  void _showLocalChatReply(String title, double price, String replyType) {
    String reply = '';
    if (replyType == 'discount') {
      reply =
          'Hi! I am really interested in "$title". Would you be open to offering a slight discount, perhaps selling it for RM ${(price * 0.85).toStringAsFixed(0)}? Let me know if that works!';
    } else if (replyType == 'meetup') {
      reply =
          'Sounds great! Let\'s meet up at the KTDI foyer or Kolej Tun Dr. Ismail student center to complete the transaction. What time works best for you?';
    } else {
      reply =
          'Thank you for the offer. However, I think I will have to pass on this one for now. Appreciate your time and good luck with the sale!';
    }

    setState(() {
      _messageController.text = reply;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Local AI Reply suggestion pasted!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildComposer(ChatModel chat) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF89986D)),
              const SizedBox(width: 6),
              const Text(
                'AI helper:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _replyChip('Request Discount',
                          () => _generateChatReply(chat, 'discount')),
                      const SizedBox(width: 6),
                      _replyChip('Confirm Meetup',
                          () => _generateChatReply(chat, 'meetup')),
                      const SizedBox(width: 6),
                      _replyChip('Polite Decline',
                          () => _generateChatReply(chat, 'decline')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    counterText: '',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _replyChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF89986D).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF89986D).withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF89986D),
          ),
        ),
      ),
    );
  }
}
