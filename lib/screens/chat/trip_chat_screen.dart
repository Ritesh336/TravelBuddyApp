import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/trip.dart';
import '../../models/message.dart';

class TripChatScreen extends StatefulWidget {
  final Trip trip;

  const TripChatScreen({super.key, required this.trip});

  @override
  _TripChatScreenState createState() => _TripChatScreenState();
}

class _TripChatScreenState extends State<TripChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Initialize chat for this trip
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false)
          .initChat(widget.trip.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    Provider.of<ChatProvider>(context, listen: false).sendMessage(message);
    _messageController.clear();
  }

  void _markMessagesAsRead(List<Message> messages) {
    if (FirebaseService.userId == null) return;
    
    final unreadMessageIds = messages
        .where((message) => !message.readBy.contains(FirebaseService.userId))
        .map((message) => message.id)
        .toList();
    
    if (unreadMessageIds.isNotEmpty) {
      Provider.of<ChatProvider>(context, listen: false)
          .markMessagesAsRead(unreadMessageIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat participants
          _buildParticipantsChips(),
          
          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messagesStream = chatProvider.messagesStream;
                
                if (messagesStream == null) {
                  return const Center(
                    child: Text('Chat not available'),
                  );
                }
                
                return StreamBuilder<QuerySnapshot>(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    final messages = snapshot.data!.docs
                        .map((doc) => Message.fromFirestore(doc))
                        .toList();
                    
                    // Mark new messages as read
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markMessagesAsRead(messages);
                    });
                    
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('No messages yet'),
                      );
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isCurrentUser = message.senderId == FirebaseService.userId;
                        
                        return _buildMessageBubble(
                          message,
                          isCurrentUser,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildParticipantsChips() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Members:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Trip owner
                FutureBuilder(
                  future: FirebaseService.firestore
                      .collection('users')
                      .doc(widget.trip.userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final userName = userData['name'] ?? 'Unknown';
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(userName),
                        avatar: const Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.amber,
                        ),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    );
                  },
                ),
                
                // Travel buddies
                ...widget.trip.travelBuddies.map((buddyId) {
                  return FutureBuilder(
                    future: FirebaseService.firestore
                        .collection('users')
                        .doc(buddyId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      
                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      final userName = userData['name'] ?? 'Unknown';
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(userName),
                          avatar: const Icon(
                            Icons.person,
                            size: 18,
                          ),
                          backgroundColor: Colors.green.withOpacity(0.1),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    final time = DateFormat('h:mm a').format(message.sentAt);
    final date = DateFormat('MMM d').format(message.sentAt);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0),
                  child: Text(
                    '$date at $time',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: () {
              // TODO: Image attachment feature
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image attachment coming soon!'),
                ),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return IconButton(
                icon: chatProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                color: Theme.of(context).primaryColor,
                onPressed: chatProvider.isLoading ? null : _sendMessage,
              );
            },
          ),
        ],
      ),
    );
  }
}