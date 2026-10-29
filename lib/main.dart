import 'package:flutter/material.dart';
import 'homescreen.dart';
import 'editcatalogscreen.dart';
import 'settingscreen.dart';
import 'profilescreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:open_library/open_library.dart';
import 'package:provider/provider.dart';
import 'auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

	await dotenv.load(fileName: ".env");

  await Supabase.initialize(
		url: dotenv.env['SUPABASE_URL']!,
		anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => OpenLibrary(),
      dispose: (_, OpenLibrary service) => service.dispose(),
      child: MaterialApp(
        title: 'HomePage',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        home: const AuthGate(),
      )
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
      //appBar: AppBar(title: const Text('This text is in the AppBar')),
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
