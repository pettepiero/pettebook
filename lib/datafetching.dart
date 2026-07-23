import 'package:open_library/open_library.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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