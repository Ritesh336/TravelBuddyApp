import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/trip_data.dart';
import '../models/trip.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import '../theme/theme_toggle.dart';
import 'trip_details_screen.dart';
import 'trips_screen.dart';
import 'profile_screen.dart';
import 'buddy/buddy_matching_screen.dart';
import 'attractions/attractions_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dateFormat = DateFormat('MMM dd');
 
  @override
  void initState() {
    super.initState();
    
    // Load user data when home screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (FirebaseService.currentUser != null && userProvider.user == null) {
      await userProvider.loadUserData();
    }
    
    // Load trip data
    await Provider.of<TripData>(context, listen: false).loadTrips();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => Provider.of<TripData>(context, listen: false).loadTrips(),
        child: CustomScrollView(
          slivers: [
            // App Bar with Image Background
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              actions: const [
                ThemeToggle(), // Add theme toggle button
                SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Travel Buddy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Replace with your own image asset
                    Image.asset(
                      'assets/images/travel_header.jpg',
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay for better text visibility
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
           
            // Welcome message with user name
            SliverToBoxAdapter(
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null 
                              ? 'Welcome, ${user.name}!' 
                              : 'Welcome, Traveler!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Where will your adventures take you next?',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Feature buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildFeatureButton(
                              context,
                              icon: Icons.add_circle,
                              label: 'New Trip',
                              color: Colors.blue,
                              onTap: () => _showAddTripDialog(context),
                            ),
                            _buildFeatureButton(
                              context,
                              icon: Icons.person_add,
                              label: 'Find Buddies',
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BuddyMatchingScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildFeatureButton(
                              context,
                              icon: Icons.map,
                              label: 'Explore',
                              color: Colors.orange,
                              onTap: () {
                                _showExploreLocationDialog(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
           
            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Upcoming Trips',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
           
            // Trip List
            Consumer<TripData>(
              builder: (context, tripData, child) {
                if (tripData.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final activeTrips = tripData.activeTrips;
               
                if (activeTrips.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flight,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming trips',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to plan your next adventure!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
               
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildTripCard(context, activeTrips[index]);
                      },
                      childCount: activeTrips.length,
                    ),
                  ),
                );
              },
            ),
            
            // Shared Trips Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Shared Trips',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            // Shared Trips List
            Consumer<TripData>(
              builder: (context, tripData, child) {
                final sharedTrips = tripData.sharedTrips.where(
                  (trip) => trip.userId != FirebaseService.userId
                ).toList();
                
                if (sharedTrips.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.share,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No shared trips yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect with travel buddies to see their trips',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildTripCard(
                          context, 
                          sharedTrips[index],
                          isShared: true,
                        );
                      },
                      childCount: sharedTrips.length,
                    ),
                  ),
                );
              },
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTripDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TripsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
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

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip, {bool isShared = false}) {
    // These trip type icons help visually categorize trips
    final IconData tripIcon = _getTripIcon(trip.name.toLowerCase());
    final Color cardColor = _getCardColor(trip.name.toLowerCase());
   
    // Calculate if the trip is soon (within 7 days)
    final bool isSoon = trip.startDate.difference(DateTime.now()).inDays < 7;
   
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailsScreen(tripId: trip.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header with Image
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                // Replace with destination-specific image or a placeholder
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    // Use a gradient as fallback for when image is loading
                    gradient: LinearGradient(
                      colors: [cardColor.withOpacity(0.7), cardColor],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Opacity(
                    opacity: 0.3,
                    child: Icon(
                      tripIcon,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
               
                // Trip name overlay
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_dateFormat.format(trip.startDate)} - ${_dateFormat.format(trip.endDate)}, ${trip.endDate.year}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                     
                      // Show badges
                      Column(
                        children: [
                          // Shared badge
                          if (isShared)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Shared',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 4),
                          
                          // Soon badge
                          if (isSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Soon',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
           
            // Card Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Trip details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.place,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.destinations} destinations',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.endDate.difference(trip.startDate).inDays + 1} days',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.checklist,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.todoList.where((todo) => todo.completed).length}/${trip.todoList.length} tasks done',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                 
                  // Complete trip checkbox (only for user's own trips)
                  if (!isShared)
                    Column(
                      children: [
                        const Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Checkbox(
                            value: trip.completed,
                            activeColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                Provider.of<TripData>(context, listen: false)
                                    .toggleTripCompletion(trip.id);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine icon based on trip name
  IconData _getTripIcon(String tripName) {
    if (tripName.contains('beach') || tripName.contains('island')) {
      return Icons.beach_access;
    } else if (tripName.contains('mountain') || tripName.contains('hiking')) {
      return Icons.landscape;
    } else if (tripName.contains('city') || tripName.contains('urban')) {
      return Icons.location_city;
    } else if (tripName.contains('road') || tripName.contains('driving')) {
      return Icons.directions_car;
    } else {
      return Icons.flight;
    }
  }

  // Helper method to determine card color based on trip name
  Color _getCardColor(String tripName) {
    if (tripName.contains('beach') || tripName.contains('island')) {
      return Colors.blue;
    } else if (tripName.contains('mountain') || tripName.contains('hiking')) {
      return Colors.green;
    } else if (tripName.contains('city') || tripName.contains('urban')) {
      return Colors.amber;
    } else if (tripName.contains('road') || tripName.contains('driving')) {
      return Colors.deepPurple;
    } else {
      return Theme.of(context).primaryColor; // Use theme's primary color
    }
  }

  void _showAddTripDialog(BuildContext context) {
    final nameController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    int destinations = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog header
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_circle,
                              color: Theme.of(context).primaryColor,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Plan New Trip',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Let\'s create your next adventure!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                     
                      // Trip name field
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Trip Name',
                          prefixIcon: Icon(Icons.bookmark),
                        ),
                      ),
                      const SizedBox(height: 20),
                     
                      // Date selection
                      Text(
                        'Travel Dates',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                     
                      // Start date
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.flight_takeoff,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: const Text('Start Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate.add(const Duration(days: 1));
                              }
                            });
                          }
                        },
                      ),
                     
                      const Divider(height: 1),
                     
                      // End date
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.flight_land,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: const Text('End Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: startDate.add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                      ),
                     
                      const SizedBox(height: 20),
                     
                      // Destinations counter
                      Text(
                        'Number of Destinations',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text('Destinations to visit'),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: destinations > 1 ? () {
                                      setState(() {
                                        destinations--;
                                      });
                                    } : null,
                                    color: destinations > 1 ? Colors.red : Colors.grey,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '$destinations',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: destinations < 10 ? () {
                                      setState(() {
                                        destinations++;
                                      });
                                    } : null,
                                    color: destinations < 10 ? Theme.of(context).primaryColor : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                     
                      const SizedBox(height: 32),
                     
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
onPressed: () {
                                if (nameController.text.trim().isNotEmpty) {
                                  if (FirebaseService.userId != null) {
                                    Provider.of<TripData>(context, listen: false).addTrip(
                                      Trip.create(
                                        userId: FirebaseService.userId!,
                                        name: nameController.text.trim(),
                                        startDate: startDate,
                                        endDate: endDate,
                                        destinations: destinations,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please log in to create a trip'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Create Trip'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _showExploreLocationDialog(BuildContext context) {
    final latController = TextEditingController(text: '40.7128');
    final lngController = TextEditingController(text: '-74.0060');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Explore Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the coordinates of the location you want to explore',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g. 40.7128',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g. -74.0060',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              const Text(
                'Example: New York (40.7128, -74.0060), London (51.5074, -0.1278), Tokyo (35.6762, 139.6503)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(latController.text);
                final lng = double.tryParse(lngController.text);
                
                if (lat != null && lng != null) {
                  // Use the first trip for the attractions map
                  // In a real app, you might want to select a trip or create a temporary one
                  final trips = Provider.of<TripData>(context, listen: false).trips;
                  final trip = trips.isNotEmpty 
                      ? trips.first 
                      : Trip.create(
                          userId: FirebaseService.userId ?? '',
                          name: 'Exploration',
                          startDate: DateTime.now(),
                          endDate: DateTime.now().add(const Duration(days: 7)),
                          destinations: 1,
                        );
                  
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttractionsMapScreen(
                        trip: trip,
                        initialLatitude: lat,
                        initialLongitude: lng,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid coordinates'),
                    ),
                  );
                }
              },
              child: const Text('Explore'),
            ),
          ],
        );
      },
    );
  }
}