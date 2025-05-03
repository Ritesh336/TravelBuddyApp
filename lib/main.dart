import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'models/trip_data.dart';
import 'theme/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/buddy_provider.dart';
import 'providers/chat_provider.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase based on platform
  if (kIsWeb) {
    // Web configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAFjE85RoDM8rlwl7oVUcAjQyJXklcfglM",
        authDomain: "travelbuddyapp-965b3.firebaseapp.com",
        projectId: "travelbuddyapp-965b3",
        storageBucket: "travelbuddyapp-965b3.firebasestorage.app",
        messagingSenderId: "923251934301",
        appId: "1:923251934301:web:4bf9f9ed59d0581933f9b4"
      ),
    );
  } else {
    // Mobile configuration (Android/iOS)
    // This uses the google-services.json for Android and
    // GoogleService-Info.plist for iOS automatically
    await Firebase.initializeApp();
  }
  
  // Initialize services
  await FirebaseService.initializeFirebase();
  
  // Initialize the trip data provider
  final tripData = TripData();
  await tripData.loadTrips();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => tripData),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => BuddyProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: const TravelBuddyApp(),
    ),
  );
}

class TravelBuddyApp extends StatelessWidget {
  const TravelBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Travel Buddy',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Check if user is logged in
    if (FirebaseService.currentUser != null) {
      // Load user data
      await userProvider.loadUserData();
      
      // Also load trip data for current user
      await Provider.of<TripData>(context, listen: false).loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          
          if (user == null) {
            // User is not logged in
            return const LoginScreen();
          }
          
          // User is logged in
          return const HomeScreen();
        }
        
        // Checking auth state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}