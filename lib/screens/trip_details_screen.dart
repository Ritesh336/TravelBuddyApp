import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/trip_data.dart';
import '../models/trip.dart';
import '../theme/theme_toggle.dart';
import 'day_details_screen.dart';
import 'profile_screen.dart';


class TripDetailsScreen extends StatelessWidget {
  final String tripId;
 
  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripData>(
      builder: (context, tripData, child) {
        final trip = tripData.getTripById(tripId);
       
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Details')),
            body: const Center(child: Text('Trip not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Flexible app bar with trip name and dates
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                actions: const [
                  ThemeToggle(), // Add theme toggle button
                  SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    trip.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Color.fromARGB(150, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Use travel header image for all trips
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
                      // Trip dates overlay
                      Positioned(
                        bottom: 60,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timelapse,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${trip.endDate.difference(trip.startDate).inDays + 1} days trip',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: trip.completed
                                ? Colors.green.withOpacity(0.9)
                                : Theme.of(context).primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trip.completed ? Icons.check_circle : Icons.schedule,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trip.completed ? 'Completed' : 'Active',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
             
              // Trip Overview Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Trip Overview',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Trip stats cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              Icons.place,
                              '${trip.destinations}',
                              'Destinations',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              Icons.directions_walk,
                              '${trip.days.fold(0, (sum, day) => sum + day.activities.length)}',
                              'Activities',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              Icons.attach_money,
                              '\$${trip.totalExpense.toStringAsFixed(0)}',
                              'Spent',
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Daily Itinerary Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_timeline,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Daily Itinerary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
             
              // Days timeline
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final day = trip.days[index];
                    final isLastDay = index == trip.days.length - 1;
                   
                    return _buildDayTimelineItem(
                      context,
                      trip,
                      day,
                      index,
                      isLastDay,
                    );
                  },
                  childCount: trip.days.length,
                ),
              ),
  
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
          floatingActionButton: trip.completed
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Provider.of<TripData>(context, listen: false)
                        .toggleTripCompletion(trip.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip marked as active'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Trip'),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    Provider.of<TripData>(context, listen: false)
                        .toggleTripCompletion(trip.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip marked as completed'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Trip'),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                // Navigate to Home
                Navigator.popUntil(context, (route) => route.isFirst);
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
      },
    );
  }


  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDayTimelineItem(BuildContext context, Trip trip, Day day, int index, bool isLastDay) {
    final activitiesCount = day.activities.length;
    final hasActivities = activitiesCount > 0;
   
    final dotColor = hasActivities ? Theme.of(context).primaryColor : Colors.grey[400]!;
   
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DayDetailsScreen(
              tripId: trip.id,
              dayId: day.id,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: hasActivities
                        ? Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Vertical line
                  if (!isLastDay)
                    Container(
                      width: 2,
                      height: 80,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
            ),
           
            // Day details
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, isLastDay ? 0.0 : 24.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, MMM d, yyyy').format(day.date),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Activity count badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: hasActivities
                                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$activitiesCount ${activitiesCount == 1 ? 'activity' : 'activities'}',
                                style: TextStyle(
                                  color: hasActivities
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                       
                        // Preview of activities
                        if (hasActivities) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          // Show only the first 2 activities in preview
                          ...day.activities.take(2).map((activity) => _buildActivityPreview(context, activity)),
                          // Show "more" indicator if there are more than 2 activities
                          if (activitiesCount > 2) ...[
                            const SizedBox(height: 8),
                            Text(
                              '+ ${activitiesCount - 2} more activities',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap to add activities for this day',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildActivityPreview(BuildContext context, Activity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getActivityIcon(activity.name.toLowerCase()),
              color: Theme.of(context).primaryColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.startTime.format()} • ${activity.location}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '\${activity.cost.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
 
  // Helper method to determine icon based on activity name
  IconData _getActivityIcon(String activityName) {
    if (activityName.contains('eat') ||
        activityName.contains('lunch') ||
        activityName.contains('dinner') ||
        activityName.contains('breakfast') ||
        activityName.contains('restaurant')) {
      return Icons.restaurant;
    } else if (activityName.contains('museum') ||
               activityName.contains('gallery') ||
               activityName.contains('temple') ||
               activityName.contains('shrine')) {
      return Icons.museum;
    } else if (activityName.contains('hike') ||
               activityName.contains('walk') ||
               activityName.contains('trek')) {
      return Icons.directions_walk;
    } else if (activityName.contains('shopping') ||
               activityName.contains('market') ||
               activityName.contains('store')) {
      return Icons.shopping_bag;
    } else if (activityName.contains('beach') ||
               activityName.contains('swim') ||
               activityName.contains('ocean')) {
      return Icons.beach_access;
    } else if (activityName.contains('hotel') ||
               activityName.contains('check-in') ||
               activityName.contains('check-out') ||
               activityName.contains('accommodation')) {
      return Icons.hotel;
    } else if (activityName.contains('flight') ||
               activityName.contains('airport') ||
               activityName.contains('plane')) {
      return Icons.flight;
    } else if (activityName.contains('train') ||
               activityName.contains('subway') ||
               activityName.contains('metro')) {
      return Icons.train;
    } else {
      return Icons.place;
    }
  }
}
