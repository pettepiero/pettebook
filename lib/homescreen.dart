import 'package:flutter/material.dart';
import 'package:pettebook/searchscreen.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pettena's Library")),
      body: Padding(
        padding: const .all(8.0),
        child: SearchBar(
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          leading: const Icon(Icons.search),
          hintText: 'Start typing to search books...',
        )
      )
    );
  }
}