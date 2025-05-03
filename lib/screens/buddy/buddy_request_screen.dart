import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/buddy_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/trip_data.dart';
import '../../models/buddy_request.dart';
import '../../services/firebase_service.dart';

class BuddyRequestScreen extends StatefulWidget {
  const BuddyRequestScreen({super.key});

  @override
  _BuddyRequestScreenState createState() => _BuddyRequestScreenState();
}

class _BuddyRequestScreenState extends State<BuddyRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final buddyProvider = Provider.of<BuddyProvider>(context, listen: false);
    await buddyProvider.loadReceivedRequests();
    await buddyProvider.loadSentRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Buddy Requests'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Received requests
          _ReceivedRequestsTab(),
          
          // Sent requests
          _SentRequestsTab(),
        ],
      ),
    );
  }
}

class _ReceivedRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BuddyProvider, TripData>(
      builder: (context, buddyProvider, tripData, child) {
        if (buddyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = buddyProvider.receivedRequests;
        
        if (requests.isEmpty) {
          return const Center(
            child: Text('No received buddy requests'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final trip = tripData.getTripById(request.tripId);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseService.firestore
                              .collection('users')
                              .doc(request.senderId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Loading...');
                            }
                            
                            if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
                              return const Text('Unknown user');
                            }
                            
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            return Text(
                              userData?['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (trip != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.flight,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trip: ${trip.name}',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Message
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(request.message),
                    ),
                    const SizedBox(height: 12),
                    
                    // Status indicator
                    if (request.status != BuddyRequestStatus.pending) ...[
                      Row(
                        children: [
                          Icon(
                            request.status == BuddyRequestStatus.accepted
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: request.status == BuddyRequestStatus.accepted
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request.status == BuddyRequestStatus.accepted
                                ? 'Accepted'
                                : 'Declined',
                            style: TextStyle(
                              color: request.status == BuddyRequestStatus.accepted
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Action buttons for pending requests
                    if (request.status == BuddyRequestStatus.pending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              buddyProvider.respondToBuddyRequest(
                                  request.id, false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                            ),
                            child: const Text('Decline'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              buddyProvider.respondToBuddyRequest(
                                  request.id, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SentRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BuddyProvider, TripData>(
      builder: (context, buddyProvider, tripData, child) {
        if (buddyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = buddyProvider.sentRequests;
        
        if (requests.isEmpty) {
          return const Center(
            child: Text('No sent buddy requests'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final trip = tripData.getTripById(request.tripId);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseService.firestore
                              .collection('users')
                              .doc(request.receiverId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Loading...');
                            }
                            
                            if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
                              return const Text('Unknown user');
                            }
                            
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            return Text(
                              userData?['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (trip != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.flight,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trip: ${trip.name}',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Message
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(request.message),
                    ),
                    const SizedBox(height: 12),
                    
                    // Status indicator
                    Row(
                      children: [
                        Icon(
                          request.status == BuddyRequestStatus.pending
                              ? Icons.schedule
                              : request.status == BuddyRequestStatus.accepted
                                  ? Icons.check_circle
                                  : Icons.cancel,
                          color: request.status == BuddyRequestStatus.pending
                              ? Colors.orange
                              : request.status == BuddyRequestStatus.accepted
                                  ? Colors.green
                                  : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          request.status == BuddyRequestStatus.pending
                              ? 'Pending'
                              : request.status == BuddyRequestStatus.accepted
                                  ? 'Accepted'
                                  : 'Declined',
                          style: TextStyle(
                            color: request.status == BuddyRequestStatus.pending
                                ? Colors.orange
                                : request.status == BuddyRequestStatus.accepted
                                    ? Colors.green
                                    : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}