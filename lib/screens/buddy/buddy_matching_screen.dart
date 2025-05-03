import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/buddy_provider.dart';
import '../../models/user_model.dart';
import '../../models/trip_data.dart';
import '../../models/trip.dart';
import 'buddy_request_screen.dart';

class BuddyMatchingScreen extends StatefulWidget {
  const BuddyMatchingScreen({super.key});

  @override
  _BuddyMatchingScreenState createState() => _BuddyMatchingScreenState();
}

class _BuddyMatchingScreenState extends State<BuddyMatchingScreen> {
  final _emailController = TextEditingController();
  bool _isSearching = false;
  UserModel? _searchedUser;

  @override
  void initState() {
    super.initState();
    _loadSuggestedBuddies();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedBuddies() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      await Provider.of<BuddyProvider>(context, listen: false)
          .findPotentialBuddies(
        user.interests,
        user.preferredDestinations,
      );
    }
  }

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchedUser = null;
    });

    try {
      final user = await Provider.of<BuddyProvider>(context, listen: false)
          .searchUserByEmail(email);
          
      setState(() {
        _searchedUser = user;
        _isSearching = false;
      });
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching user: $e')),
      );
    }
  }

  void _showBuddyRequestDialog(UserModel buddy) {
    final tripData = Provider.of<TripData>(context, listen: false);
    final activeTrips = tripData.activeTrips;

    if (activeTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to have an active trip to invite a buddy'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return BuddyRequestDialog(
          buddy: buddy,
          trips: activeTrips,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Travel Buddies'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuddyRequestScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search by email section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find a Buddy by Email',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Enter email address',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _searchUser,
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search result
                if (_searchedUser != null)
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: _searchedUser!.profileImageUrl.isNotEmpty
                            ? NetworkImage(_searchedUser!.profileImageUrl)
                            : null,
                        child: _searchedUser!.profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      title: Text(_searchedUser!.name),
                      subtitle: Text(_searchedUser!.email),
                      trailing: ElevatedButton(
                        onPressed: () => _showBuddyRequestDialog(_searchedUser!),
                        child: const Text('Invite'),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Suggested buddies section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Suggested Travel Buddies',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadSuggestedBuddies,
                      tooltip: 'Refresh suggestions',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Buddy list
          Expanded(
            child: Consumer<BuddyProvider>(
              builder: (context, buddyProvider, child) {
                if (buddyProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final buddies = buddyProvider.suggestedBuddies;
                
                if (buddies.isEmpty) {
                  return const Center(
                    child: Text(
                      'No suggested buddies found.\nTry adding more interests or destinations to your profile.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: buddies.length,
                  itemBuilder: (context, index) {
                    final buddy = buddies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).primaryColor,
                                backgroundImage: buddy.profileImageUrl.isNotEmpty
                                    ? NetworkImage(buddy.profileImageUrl)
                                    : null,
                                child: buddy.profileImageUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              title: Text(
                                buddy.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (buddy.interests.isNotEmpty) ...[
                              const Text(
                                'Interests:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: buddy.interests
                                    .take(5)
                                    .map(
                                      (interest) => Chip(
                                        label: Text(interest),
                                        backgroundColor: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if (buddy.preferredDestinations.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Destinations:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: buddy.preferredDestinations
                                    .take(3)
                                    .map(
                                      (destination) => Chip(
                                        label: Text(destination),
                                        backgroundColor:
                                            Colors.green.withOpacity(0.1),
                                        side: BorderSide(
                                          color:
                                              Colors.green.withOpacity(0.2),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showBuddyRequestDialog(buddy),
                                icon: const Icon(Icons.person_add),
                                label: const Text('Invite as Travel Buddy'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Dialog to send buddy request
class BuddyRequestDialog extends StatefulWidget {
  final UserModel buddy;
  final List<Trip> trips;

  const BuddyRequestDialog({
    super.key,
    required this.buddy,
    required this.trips,
  });

  @override
  _BuddyRequestDialogState createState() => _BuddyRequestDialogState();
}

class _BuddyRequestDialogState extends State<BuddyRequestDialog> {
  late String _selectedTripId;
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.trips.first.id;
    _messageController.text = 'Hi! Would you like to join me on my trip?';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await Provider.of<BuddyProvider>(context, listen: false).sendBuddyRequest(
        receiverId: widget.buddy.id,
        tripId: _selectedTripId,
        message: _messageController.text.trim(),
      );

      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent to ${widget.buddy.name}')),
      );
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending invitation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Travel Buddy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: widget.buddy.profileImageUrl.isNotEmpty
                      ? NetworkImage(widget.buddy.profileImageUrl)
                      : null,
                  child: widget.buddy.profileImageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.buddy.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.buddy.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a trip to invite them to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTripId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.trips.map((trip) {
                return DropdownMenuItem<String>(
                  value: trip.id,
                  child: Text(trip.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTripId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Add a personal message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write a message...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendRequest,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }
}