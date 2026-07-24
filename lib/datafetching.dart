import 'package:flutter/cupertino.dart';
import 'package:open_library/open_library.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:open_library/open_library.dart';
import 'package:open_library/models/ol_book_model.dart';
import 'package:open_library/models/ol_search_model.dart';
import 'package:provider/provider.dart';

class BookRepository {
  final List<String> _localCatalog = ["Moby Dick", "1984", "Nexus"];

  Future<List<String>> searchLocalCatalog(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lowerQuery = query.toLowerCase();
    return _localCatalog
        .where((book) => book.toLowerCase().contains(lowerQuery))
        .toList();
  }

  //Future<List<String>> searchOnlineApi(String query) async {
  //  try {

  //  }
  //}
}

Future<List<String>> localSearch(List<String> booklist, String query) async {
  // Optional: Simulate a tiny delay so your SearchScreen can show a loading indicator
  await Future.delayed(const Duration(milliseconds: 300));

  // If the search bar is empty, return all books (or return an empty list [])
  if (query.isEmpty) {
    return booklist;
  }

  // Convert the query to lowercase for a case-insensitive search
  final lowerCaseQuery = query.toLowerCase();

  // Filter the list
  return booklist.where((book) {
    return book.toLowerCase().contains(lowerCaseQuery);
  }).toList();
}
// END OF LOCAL SEARCH OF BOOKS


Future<List<String>> supabaseSearch(String query) async {
  final supabase = Supabase.instance.client;
  final result = await supabase
      .from('book_tab')
      .select('title')
      .ilike('title', '%$query%');

  return result.map((row) => row['title'] as String).toList();
}

Future<List<String>> openlibrarySearch(String query, BuildContext context) async {
  debugPrint('Called openlibrarySearch function');
  final lowerCaseQuery = query.toLowerCase();
  if (query.isEmpty) {
    return [];
  }
  final openLib = Provider.of<OpenLibrary>(context, listen: false);
  debugPrint('openLib found: $openLib');
  debugPrint('query is: $lowerCaseQuery');

  try {
    final result = await openLib.query(title: lowerCaseQuery);
    if (result is OLSearch) {
      debugPrint('Found results: $result');
      return result.docs.map((doc) => doc.title ?? "Unknown Title").toList();
    }
    debugPrint('result is not OLSearch');
    return [];
  } catch (error) {
    debugPrint('OpenLibrary Search failed: $error');
    return [];
  }
}
