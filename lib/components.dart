import 'package:flutter/material.dart';


// Search Bar
class MySearchBar extends StatelessWidget{
  final String hintText;
  final WidgetBuilder targetSearchScreenBuilder;

  const MySearchBar({
    super.key,
    required this.targetSearchScreenBuilder,
    this.hintText = "Type here...",
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 16.0),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: targetSearchScreenBuilder),
        );
      },
      leading: const Icon(Icons.search),
      hintText: hintText,
    );
  }
}