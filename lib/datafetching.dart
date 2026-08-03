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


Future<List<Map<String, dynamic>>> openlibrarySearch(String query, BuildContext context) async {
  debugPrint('Called direct HTTP openlibrarySearch function');
  
  if (query.isEmpty) return [];

  try {
    // 1. Call the Open Library Search API directly
    final url = Uri.parse('https://openlibrary.org/search.json?title=${Uri.encodeComponent(query)}&limit=15');
    final response = await http.get(url);

    debugPrint("\n\nresponse: $response\n\n");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final docs = data['docs'] as List<dynamic>;

      return docs.map((doc) {
        final title = doc['title']?.toString() ?? 'Unknown Title';

        final authorsList = doc['author_name'] as List<dynamic>?;
        final author = (authorsList != null && authorsList.isNotEmpty) 
            ? authorsList.join(', ') 
            : 'Unknown Author';

        final year = doc['first_publish_year']?.toString() ?? '';

        final pubList = doc['publisher'] as List<dynamic>?;
        final pub = (pubList != null && pubList.isNotEmpty) ? pubList.first.toString() : '';

        final isbnList = doc['isbn'] as List<dynamic>?;
        final isbn = (isbnList != null && isbnList.isNotEmpty) ? isbnList.first.toString() : '';
        final coverId = doc['cover_i']?.toString() ?? '';
        final workKey = doc['key']?.toString() ?? '';

        return {
          'title': title,
          'authors': author,
          'year': year,
          'pub': pub,
          'isbn': isbn,
          'cover_id': coverId,
          'workKey': workKey,
        };
      }).toList();
    }
    
    return [];
  } catch (error) {
    debugPrint('OpenLibrary HTTP Search failed: $error');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchEditionsFromWork(String workKey) async {
  if (workKey.isEmpty) return [];

  debugPrint('Fetching editions for work: $workKey');
  try {
    final url = Uri.parse('https://openlibrary.org$workKey/editions.json');
    final response = await http.get(url);

    if (response.statusCode == 200){
      final data = json.decode(response.body);
      final entries = data['entries'] as List<dynamic>? ?? [];

      return entries.map((edition) {
        final title = edition['title']?.toString() ?? 'Unknown Title';
        final date = edition['publish_date']?.toString() ?? 'Unknown Date';

        final publishers = edition['publishers'] as List<dynamic>?;
        final publisher = publishers != null && publishers.isNotEmpty
            ? publishers.first.toString() : 'Unknown Publisher';

        final isbn13List = edition['isbn_13'] as List<dynamic>?;
        final isbn10List = edition['isbn_10'] as List<dynamic>?;

        String editionIsbn = '';
        if (isbn13List != null && isbn13List.isNotEmpty) {
          editionIsbn = isbn13List.first.toString();
        } else if (isbn10List != null && isbn10List.isNotEmpty){
          editionIsbn = isbn10List.first.toString();
        }

        final covers = edition['covers'] as List<dynamic>?;
        final coverId = covers != null && covers.isNotEmpty
          ? covers.first.toString() : '';

        return {
          'title': title,
          'yaer': date,
          'pub': publisher,
          'isbn': editionIsbn,
          'cover_id': coverId,
        };
      }).toList();
    }
    return [];
  } catch (error) {
    debugPrint("Failed to fetch editions: $error");
    return [];
  }
}