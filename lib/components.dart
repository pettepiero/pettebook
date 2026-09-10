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

/// Function that handles the most common name structures, including multiple
/// middle names, common suffixes and surname prefixes. It returns a first name
/// and a last name in a reasonable way. Handling 100% of possible scenarios is
/// not possible.
Map<String, String> splitFullName(String fullName) {
  // 1. Clean the input (remove leading/trailing spaces and double spaces)
  final cleanedName = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleanedName.isEmpty) return {'firstName': '', 'lastName': ''};

  List<String> parts = cleanedName.split(' ');

  // 2. Handle Mononyms (e.g., "Plato", "Cher")
  if (parts.length == 1) {
    return {'firstName': parts[0], 'lastName': ''};
  }

  // 3. Extract and preserve common suffixes
  final knownSuffixes = {
    'jr',
    'jr.',
    'sr',
    'sr.',
    'ii',
    'iii',
    'iv',
    'phd',
    'md',
    'esq',
  };
  String suffix = '';

  if (knownSuffixes.contains(parts.last.toLowerCase())) {
    suffix = ' ${parts.removeLast()}'; // Remove suffix from parts and save it
  }

  // If only one name is left after removing the suffix (e.g., "Prince Jr.")
  if (parts.length == 1) {
    return {'firstName': parts[0], 'lastName': suffix.trim()};
  }

  // 4. Look for common compound surname prefixes
  final surnamePrefixes = {
    'van',
    'von',
    'de',
    'del',
    'della',
    'di',
    'da',
    'la',
    'le',
    'mac',
    'mc',
    'st',
    'st.',
  };

  int lastNameStartIndex = parts.length - 1; // Default to the very last word

  for (int i = 0; i < parts.length - 1; i++) {
    // If we hit a prefix like "de" or "von", everything from here on is the last name
    if (surnamePrefixes.contains(parts[i].toLowerCase())) {
      lastNameStartIndex = i;
      break;
    }
  }

  // 5. Construct the final strings
  final firstName = parts.sublist(0, lastNameStartIndex).join(' ');
  final lastName = parts.sublist(lastNameStartIndex).join(' ') + suffix;

  return {'firstName': firstName, 'lastName': lastName};
}

/// Function that strips common words and remove punctuation etc.. to effectively
/// compare publisher name strings
String normalizePublisherName(String name) {
  // 1. Convert to lowercase and remove punctuation
  String normalized = name.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '') // Removes commas, periods, hyphens, etc.
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');  // Fixes double spaces

  // 2. Define words to strip out (add more as needed for your specific dataset)
  final stopWords = [
    'editore', 'edizioni', 'librerie', 'libreria', 'spa', 'srl', 
    'inc', 'ltd', 'llc', 'press', 'books', 'publishing', 'group', 
    'media', 'and', 'sons', 'company', 'co'
  ];

  // 3. Remove stop words if they appear as isolated words
  List<String> words = normalized.split(' ');
  words.removeWhere((word) => stopWords.contains(word));

  // 4. Rejoin the string
  return words.join(' ').trim();
}