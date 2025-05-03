import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/theme_provider.dart';
import '../providers/user_provider.dart';
import '../models/trip_data.dart';
import '../services/firebase_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _interestController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _interestController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _uploadProfileImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final userId = FirebaseService.userId;
        final storageRef =
            FirebaseStorage.instance.ref().child('profile_images/$userId.jpg');

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        await Provider.of<UserProvider>(context, listen: false)
            .updateUserProfile(profileImageUrl: downloadUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentInterests = List<String>.from(userProvider.user?.interests ?? []);
      
      if (!currentInterests.contains(interest)) {
        currentInterests.add(interest);
        userProvider.updateUserProfile(interests: currentInterests);
        _interestController.clear();
      }
    }
  }

  void _removeInterest(String interest) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentInterests = List<String>.from(userProvider.user?.interests ?? []);
    
    currentInterests.remove(interest);
    userProvider.updateUserProfile(interests: currentInterests);
  }

  void _addDestination() {
    final destination = _destinationController.text.trim();
    if (destination.isNotEmpty) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentDestinations = List<String>.from(
          userProvider.user?.preferredDestinations ?? []);
      
      if (!currentDestinations.contains(destination)) {
        currentDestinations.add(destination);
        userProvider.updateUserProfile(
            preferredDestinations: currentDestinations);
        _destinationController.clear();
      }
    }
  }

  void _removeDestination(String destination) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentDestinations = List<String>.from(
        userProvider.user?.preferredDestinations ?? []);
    
    currentDestinations.remove(destination);
    userProvider.updateUserProfile(preferredDestinations: currentDestinations);
  }

  Future<void> _signOut() async {
    try {
      await FirebaseService.signOut();
      
      if (!mounted) return;
      // Clear user data in provider
      Provider.of<UserProvider>(context, listen: false).clearUser();
      
      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tripData = Provider.of<TripData>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (user == null) {
            return const Center(
              child: Text('Please sign in to view your profile'),
            );
          }
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor,
                          backgroundImage: user.profileImageUrl.isNotEmpty
                              ? NetworkImage(user.profileImageUrl)
                              : null,
                          child: user.profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : _isUploadingImage
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: _uploadProfileImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Traveler since ${user.createdAt.year}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Profile Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(
                    context,
                    '${tripData.trips.length}',
                    'Trips',
                  ),
                  _buildStat(
                    context,
                    '${tripData.trips.fold(0, (sum, trip) => sum + trip.destinations)}',
                    'Places',
                  ),
                  _buildStat(
                    context,
                    '${user.interests.length}',
                    'Interests',
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Travel Interests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _interestController,
                      decoration: const InputDecoration(
                        hintText: 'Add a travel interest',
                        prefixIcon: Icon(Icons.interests),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: Theme.of(context).primaryColor,
                    onPressed: _addInterest,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: user.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeInterest(interest),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Preferred Destinations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        hintText: 'Add a preferred destination',
                        prefixIcon: Icon(Icons.place),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: Theme.of(context).primaryColor,
                    onPressed: _addDestination,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: user.preferredDestinations.map((destination) {
                  return Chip(
                    label: Text(destination),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeDestination(destination),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    side: BorderSide(color: Colors.green.withOpacity(0.2)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeSettingItem(
                context,
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                'Theme',
                themeProvider.isDarkMode ? 'Switch to Light theme' : 'Switch to Dark theme',
                themeProvider,
              ),
              _buildSettingItem(
                context,
                Icons.notifications,
                'Notifications',
                'Manage your notification preferences',
              ),
              _buildSettingItem(
                context,
                Icons.language,
                'Language',
                'Change application language',
              ),
              _buildSettingItem(
                context,
                Icons.security,
                'Privacy',
                'Manage your privacy settings',
              ),
              _buildSettingItem(
                context,
                Icons.help,
                'Help & Support',
                'Get assistance or report issues',
              ),
              
              const SizedBox(height: 24),         
              // App Info
              Center(
                child: Text(
                  'Travel Buddy v1.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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


  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    );
  }


  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle navigation to respective settings screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title feature coming soon!'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
  
 
  Widget _buildThemeSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    ThemeProvider themeProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        value: themeProvider.isDarkMode,
        activeColor: Theme.of(context).primaryColor,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
      ),
    );
  }
}