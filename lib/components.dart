import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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

Widget buildImagePlaceholder() {
  return Container(
    width: double.infinity,
    color: Colors.deepPurple.shade50,
    child: const Icon(Icons.book, size: 48, color: Colors.deepPurple)
  );
}

Future<bool> addToLibrary(Map<String, dynamic> book) async {
  try {
    final supabase = Supabase.instance.client;
    await supabase.from('books').insert(book);

    return true;
  } catch (e) {
    print("Error adding book: $e");
    return false;
  }
}