import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'providers/rides_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_rides_screen.dart';
import 'screens/profile_screen.dart';

const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDAunvv-65r5NmLqSfS3v6eq4W7bE-I-yI",
  authDomain: "sgp-2-debce.firebaseapp.com",
  projectId: "sgp-2-debce",
  storageBucket: "sgp-2-debce.firebasestorage.app",
  messagingSenderId: "464842482641",
  appId: "1:464842482641:android:ee7f242aef0daeed2e36f0",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    debugPrint("Firebase init notice: $e");
  }
  runApp(const AutoShareApp());
}

class AutoShareApp extends StatelessWidget {
  const AutoShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RidesProvider(),
      child: Consumer<RidesProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'AutoShare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MyRidesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RidesProvider>();

    if (provider.authLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0D9488),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'My Rides',
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

