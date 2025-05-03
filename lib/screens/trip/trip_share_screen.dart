import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip.dart';
import '../../models/trip_data.dart';
import '../../services/firebase_service.dart';

class TripShareScreen extends StatefulWidget {
  final String tripId;

  const TripShareScreen({super.key, required this.tripId});

  @override
  _TripShareScreenState createState() => _TripShareScreenState();
}

class _TripShareScreenState extends State<TripShareScreen> {
  bool _isLoading = false;
  bool _isShared = false;

  @override
  void initState() {
    super.initState();
    _loadTripStatus();
  }

  void _loadTripStatus() {
    final trip = Provider.of<TripData>(context, listen: false)
        .getTripById(widget.tripId);
    
    if (trip != null) {
      setState(() {
        _isShared = trip.isShared;
      });
    }
  }

  Future<void> _toggleSharing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<TripData>(context, listen: false)
          .toggleTripSharing(widget.tripId);
      
      final trip = Provider.of<TripData>(context, listen: false)
          .getTripById(widget.tripId);
      
      if (trip != null) {
        setState(() {
          _isShared = trip.isShared;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating sharing status: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripData>(
      builder: (context, tripData, child) {
        final trip = tripData.getTripById(widget.tripId);
        
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Share Trip')),
            body: const Center(child: Text('Trip not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Share ${trip.name}'),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sharing status card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isShared ? Icons.public : Icons.public_off,
                              color: _isShared ? Colors.green : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isShared
                                        ? 'Trip Sharing is Enabled'
                                        : 'Trip Sharing is Disabled',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isShared
                                        ? 'Your trip is visible to your travel buddies'
                                        : 'Your trip is private and only visible to you',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isShared,
                              activeColor: Colors.green,
                              onChanged: _isLoading
                                  ? null
                                  : (value) => _toggleSharing(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Travel buddies section
                const Text(
                  'Travel Buddies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // List of travel buddies
                Expanded(
                  child: trip.travelBuddies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No travel buddies yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Invite friends to join your trip',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: trip.travelBuddies.length,
                          itemBuilder: (context, index) {
                            final buddyId = trip.travelBuddies[index];
                            
                            return FutureBuilder(
                              future: FirebaseService.firestore
                                  .collection('users')
                                  .doc(buddyId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const ListTile(
                                    leading: CircleAvatar(
                                      child: CircularProgressIndicator(),
                                    ),
                                    title: Text('Loading...'),
                                  );
                                }
                                
                                if (!snapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }
                                
                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: userData['profileImageUrl'] != null &&
                                            userData['profileImageUrl'].isNotEmpty
                                        ? NetworkImage(userData['profileImageUrl'])
                                        : null,
                                    child: userData['profileImageUrl'] == null ||
                                            userData['profileImageUrl'].isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(userData['name'] ?? 'Unknown User'),
                                  subtitle: Text(userData['email'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                    onPressed: () {
                                      _showRemoveBuddyDialog(context, trip, buddyId, userData['name']);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/buddyMatching');
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Invite Buddy'),
          ),
        );
      },
    );
  }

  void _showRemoveBuddyDialog(
    BuildContext context,
    Trip trip,
    String buddyId,
    String? buddyName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Travel Buddy'),
          content: Text(
            'Are you sure you want to remove ${buddyName ?? "this buddy"} from your trip?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Provider.of<TripData>(context, listen: false)
                    .removeTravelBuddy(trip.id, buddyId);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${buddyName ?? "Buddy"} removed from trip'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}