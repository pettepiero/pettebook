import 'package:flutter/cupertino.dart';
import 'package:open_library/open_library.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:open_library/models/ol_search_model.dart';
import 'package:provider/provider.dart';

//LOCAL SEARCH: needs to be fixed to return Future<List<Map<String, dynamic>>>

//Future<List<Map<String, dynamic>>> localSearch(List<String> booklist, String query) async {
//  // Optional: Simulate a tiny delay so your SearchScreen can show a loading indicator
//  await Future.delayed(const Duration(milliseconds: 300));
//
//  // If the search bar is empty, return all books (or return an empty list [])
//  if (query.isEmpty) {
//    return booklist;
//  }
//
//  // Convert the query to lowercase for a case-insensitive search
//  final lowerCaseQuery = query.toLowerCase();
//
//  // Filter the list
//  return booklist.where((book) {
//    return book.toLowerCase().contains(lowerCaseQuery);
//  }).toList();
//}
// END OF LOCAL SEARCH OF BOOKS


Future<List<Map<String, dynamic>>> supabaseSearch(String query) async {
  final supabase = Supabase.instance.client;

  try {
    final List<Map<String, dynamic>> result = await supabase
        .from('book_tab')
        .select('''
          title,
          year,
          publisher_tab(
            pub_name
            ),
          author_tab (
            author_f_name,
            author_l_name
            )
        ''')
        .ilike('title', '%$query%');
    debugPrint('Supabase Raw Output: $result');
    final formattedResult = result.map((row){
      final authorData = row['author_tab'] as Map<String, dynamic>?;
      final firstName = authorData?['author_f_name'] ?? '';
      final lastName = authorData?['author_l_name'] ?? '';
      final pubData = row['publisher_tab'] as Map<String, dynamic>?;
      final pubName = pubData?['pub_name'] ?? '';
      final year = row['year'] ?? '';

      return {
        'title': row['title'],
        'authors': '$firstName $lastName'.trim(),
        'year': year,
        'pub': pubName,
      };
    }).toList();
    debugPrint('Formatted Output: $formattedResult');
    return formattedResult;
  } catch (error) {
    debugPrint('Supabase Search Error: $error');
    return [];
  }
}

Future<List<Map<String, dynamic>>> openlibrarySearch(String query, BuildContext context) async {
  debugPrint('Called openlibrarySearch function');
  final lowerCaseQuery = query.toLowerCase();
  if (query.isEmpty) {
    return [];
  }
  final openLib = Provider.of<OpenLibrary>(context, listen: false);

  try {
    final result = await openLib.query(title: lowerCaseQuery);
    if (result is OLSearch) {
      debugPrint('Found results: $result');
      return result.docs.map((doc) {
       final title = doc.title ;
       //final author = doc.authors ?? "Unknown Author";
       final author = doc.authors.isNotEmpty
           ? doc.authors.map((a) => a.name).join(', ')
           : "Unknown Author";
       final year = doc.publish_year;
       final pub = doc.publisher;
       return {
         'title': title,
         'authors': author,
         'year': year,
         'pub': pub,
       };
      }).toList();
    }
    debugPrint('result is not OLSearch');
    return [];
  } catch (error) {
    debugPrint('OpenLibrary Search failed: $error');
    return [];
  }
}
