import 'package:flutter/material.dart';
import 'homescreen.dart';
import 'searchscreen.dart';
import 'editcatalogscreen.dart';
import 'settingscreen.dart';
import 'profilescreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eckybvuccyssfwicdhim.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVja3lidnVjY3lzc2Z3aWNkaGltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MDE3MTYsImV4cCI6MjA5NDA3NzcxNn0.LaOeph0RiDLaph65rSR8XdqDzLW5Yiu2p04ujkO-M04',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomePage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black12,
      ),
      home: Material3BottomNav(),
    );
  }
}

class Material3BottomNav extends StatefulWidget {
  const Material3BottomNav({super.key});

  @override
  State<Material3BottomNav> createState() => _Material3BottomNavState();
}

class _Material3BottomNavState extends State<Material3BottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const EditCatalogScreen(),
    const SettingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('This text is in the AppBar')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(seconds: 1),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _navBarItems,
      ),
    );
  }
}

const _navBarItems = [
  NavigationDestination(
    icon: Icon(Icons.menu_book_outlined),
    selectedIcon: Icon(Icons.menu_book_rounded),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.edit_note_outlined),
    selectedIcon: Icon(Icons.edit_note_rounded),
    label: 'Edit Catalog',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings_rounded),
    label: 'Settings',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline_rounded),
    selectedIcon: Icon(Icons.person_rounded),
    label: 'Profile',
  ),
];
