import 'package:flutter/cupertino.dart';
import 'package:open_library/open_library.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:open_library/models/ol_search_model.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> supabaseSearch(String query) async {
  final supabase = Supabase.instance.client;

  try {
    final List<Map<String, dynamic>> result = await supabase
        .from('book_tab')
        .select('''
          title,
          isbn,
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
      final rawYear = row['year'];
      final year = rawYear is List
        ? (rawYear.isNotEmpty ? rawYear.first.toString(): '')
        : rawYear?.toString() ?? ''; 
      final rawIsbn = row['isbn'];
      final isbn = rawIsbn is List
        ? (rawIsbn.isNotEmpty ? rawIsbn.first.toString(): '')
        : rawIsbn?.toString() ?? ''; 

      return {
        'title': row['title'],
        'authors': '$firstName $lastName'.trim(),
        'year': year,
        'pub': pubName,
        'isbn': isbn,
      };
    }).toList();
    debugPrint('Formatted Output: $formattedResult');
    return formattedResult;
  } catch (error) {
    debugPrint('Supabase Search Error: $error');
    return [];
  }
}

//Future<List<Map<String, dynamic>>> openlibrarySearch(String query, BuildContext context) async {
//  debugPrint('Called openlibrarySearch function');
//  final lowerCaseQuery = query.toLowerCase();
//  if (query.isEmpty) {
//    return [];
//  }
//  final openLib = Provider.of<OpenLibrary>(context, listen: false);
//
//  try {
//    final result = await openLib.query(title: lowerCaseQuery);
//    if (result is OLSearch) {
//      debugPrint('Found results: $result');
//      return result.docs.map((doc) {
//       final title = doc.title ;
//       //final author = doc.authors ?? "Unknown Author";
//       final author = doc.authors.isNotEmpty
//           ? doc.authors.map((a) => a.name).join(', ')
//           : "Unknown Author";
//       final year = doc.publish_year.isNotEmpty ? doc.publish_year.first.toString() : '';
//       final pub = doc.publisher.isNotEmpty ? doc.publisher.first.toString() : '';
//       final isbn = doc.isbn.isNotEmpty ? doc.isbn.first.toString() : '';
//       return {
//          'title': title,
//          'authors': author,
//          'year': year,
//          'pub': pub,
//          'isbn': isbn,
//       };
//      }).toList();
//    }
//    debugPrint('result is not OLSearch');
//    return [];
//  } catch (error) {
//    debugPrint('OpenLibrary Search failed: $error');
//    return [];
//  }
//}


Future<List<Map<String, dynamic>>> openlibrarySearch(String query, BuildContext context) async {
  debugPrint('Called direct HTTP openlibrarySearch function');
  
  if (query.isEmpty) return [];

  try {
    // 1. Call the Open Library Search API directly
    final url = Uri.parse('https://openlibrary.org/search.json?title=${Uri.encodeComponent(query)}&limit=15');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final docs = data['docs'] as List<dynamic>;

      return docs.map((doc) {
        // 2. Extract Title
        final title = doc['title']?.toString() ?? 'Unknown Title';

        // 3. Extract Authors (API returns 'author_name' as a list of strings)
        final authorsList = doc['author_name'] as List<dynamic>?;
        final author = (authorsList != null && authorsList.isNotEmpty) 
            ? authorsList.join(', ') 
            : 'Unknown Author';

        // 4. Extract Year (Prefer 'first_publish_year' as it is a single integer)
        final year = doc['first_publish_year']?.toString() ?? '';

        // 5. Extract Publisher (API returns 'publisher' as a list of strings)
        final pubList = doc['publisher'] as List<dynamic>?;
        final pub = (pubList != null && pubList.isNotEmpty) ? pubList.first.toString() : '';

        // 6. Extract ISBN (API returns 'isbn' as a list of strings)
        final isbnList = doc['isbn'] as List<dynamic>?;
        final isbn = (isbnList != null && isbnList.isNotEmpty) ? isbnList.first.toString() : '';

        return {
          'title': title,
          'authors': author,
          'year': year,
          'pub': pub,
          'isbn': isbn,
        };
      }).toList();
    }
    
    return [];
  } catch (error) {
    debugPrint('OpenLibrary HTTP Search failed: $error');
    return [];
  }
}