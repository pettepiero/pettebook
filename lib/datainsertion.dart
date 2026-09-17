import 'package:flutter/material.dart';
import 'package:pettebook/components.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;


/// The outermost layer of the methods that allow adding a book to the database.
Future<bool> bookAdder({
  required Map<String, dynamic> book, 
  required String shelfId, 
  required String householdId, 
  required String userId
  }) async {
  // First, check if ISBN is present
  debugPrint("In bookAdder: book: $book");
  if (book['isbn'] != null && book['isbn'].toString().isNotEmpty)  {
    debugPrint("Got isbn: ${book['isbn']}");
    debugPrint("Running addFromISBN");
    return addFromISBN(book, shelfId, householdId, userId);
  } else {
    Map<String, dynamic> bookInfo = await getMissingInfo(book);
    return manualInsertion(bookInfo);
  }
}

/// Function to add a book using its ISBN code. First, it checks if
/// the ISBN code is already present in the databse. If it isn't, it
/// fetches all the data it can using the OpenLibrary (OL) ISBN API. Then
/// it retrieves the author information using its OL author key and publisher
/// information. Once it has all the data, it adds the entry to the database.
///
/// If it doesn't find the ISBN code from OL catalog, it asks the user to insert
/// the entry manually using manualInsertion method.
Future<bool> addFromISBN(Map<String, dynamic> book, String shelfId, String householdId, String userId) async {
  // Check if ISBN is already present in the database.
  String isbn = book['isbn'];
  final isPresent = await isPresentISBN(isbn);

  if (isPresent) {
    debugPrint("\nERROR: This ISBN code is already present in the library!");
    return false;
  } else {
    // The ISBN code is not present in the database so we can proceed with
    // searching for info using the OpenLibrary API
    try {
      final url = Uri.parse('https://openlibrary.org/isbn/$isbn.json');
      debugPrint("\n Created url: $url");
      final response = await http.get(url);

      debugPrint("response.statusCode: ${response.statusCode}");
      if (response.statusCode == 200){
        final Map<String, dynamic> data = json.decode(response.body);

        debugPrint("Candidate entry: $data");

        // Extracts the data
        Map<String, dynamic> entryData = await olBookDataExtractor(data);
				debugPrint("Returned from olBookDataExtractor safely \n");

        // Add the last missing data for insertion:
        // shelfId, userId, household_id
        entryData['shelf_id'] = shelfId;
        entryData['user_id'] = userId;
        entryData['household_id'] = householdId;

				debugPrint("Final candidate data: ");
				for (final e in entryData.entries) {
				  debugPrint("${e.key} = ${e.value}");
				}	
	
				final supabase = Supabase.instance.client;

				final insertResponse = await supabase
				  .from('book_tab')
				  .insert(entryData);
        
      }
    } catch (error) {
      debugPrint("Failed to search ISBN in database: $error");
      return false; 
    }

    return true;
  }
}

/// Given an ISBN string, returns true if it is already present in book_tab
Future<bool> isPresentISBN(String isbn) async {
  final supabase = Supabase.instance.client;

	String? colName = null;
	// Modify this to check both isbn_13 and isbn_10 from book_tab
	if (isbn.length == 13) {
		colName = 'isbn_13';
	} else if (isbn.length == 10) {
		colName = 'isbn_10';
	} else {
		throw StateError("Length of ISBN is neither 13 nor 10.");	
	}	

  final res = await supabase
      .from('book_tab')
      .select(colName)
      .eq(colName, isbn)
      .limit(1);

  return res.isNotEmpty;
}

/// Given a Map of book data from OL, extracts only the necessary data 
/// for the database.
/// Note: authorId is first set to null, and then it is obtained by the dedicated
/// function getAuthorID. Same thing happens for publisherId.
Future<Map<String, dynamic>> olBookDataExtractor(Map<String, dynamic> book) async {
  debugPrint("in olBookDataExtractor");
  debugPrint("type of book['authors']: ${book['authors'].runtimeType}");
  debugPrint("isbn_13: ${book['isbn_13']}");

  final authorId = await getAuthorID(authors: book['authors']);
  final publisherId = await getPublisherID(publishers: book['publishers']);

  debugPrint("\n\n Obtained authorId: $authorId and publisherId: $publisherId");
	debugPrint("isbn_13: ${book['isbn_13']}");
	debugPrint("isbn_10: ${book['isbn_10']}");

  return {
    'title': book['title'],
    'author_id': authorId?.first,
    'isbn_13': book['isbn_13'] !=null ? book['isbn_13'].first : null,
    'isbn_10': book['isbn_10'] !=null ? book['isbn_10'].first : null,
    'publisher_id': publisherId?.first,
    'year': book['year'],
    'lent': false,
    'borrowed_to': null,
    'languages': (book['languages'] != null)
        ? (book['languages'] as List).map((lang) => 
            (lang['key'] as String).replaceAll('/languages/', '')).toList()
        : [''],
  };
}

/// Given a list of OL author keys, fetches the names using the author API and
/// subsequently searches them in database to obtain the local index. If the 
/// author is not present in the database, it is added and the new id is returned.
Future<List<String>?> getAuthorID({required List<dynamic> authors}) async {
  debugPrint("In getAuthorID: passed authors: $authors");
  final supabase = Supabase.instance.client;
  List<String> processAuthorIds = [];

  // Fetch the authors table once before the loop.
  // TODO: if the database grows big, this needs to be made more efficient.
  final PostgrestList res = await supabase
    .from('author_tab')
    .select('author_f_name, author_l_name, author_id');

  debugPrint("Got over supabase query: $res");

  Map<String, String> authorsMap = {
    for (var author in res)
      author['author_id'] as String: '${author['author_f_name']} ${author['author_l_name']}'
  };

  debugPrint("Got authorsMap: $authorsMap");
  
  for (var authorMap in authors) {
    try {
      debugPrint("\n\n*********************\nDEBUG: doing authorMap: $authorMap");
      final String? authorPath = authorMap['key'];
      debugPrint("DEBUG: authorPath: $authorPath");
      if (authorPath == null) continue;

      final url = Uri.parse('https://openlibrary.org$authorPath.json');
      debugPrint("DEBUG: url: $url");
      final response = await http.get(url);

      if (response.statusCode == 200){
        final data = json.decode(response.body);

        String personalName = data['personal_name'] ?? data['name'] ?? 'Unknown Author';
        List<dynamic> rawAltNames = data['alternate_names'] ?? [];
        List<String> candidateNames = rawAltNames.map((e) => e.toString()).toList();
        candidateNames.insert(0, personalName);

        String? matchedAuthorId;

        // Now we need to search for personalName in database and if present
        // retrieve the index. If not present, repeat with alternateNames. If
        // not present again, create new index by increasing the highest author_id.
        // This is done by comparing the list of authors from the database with
        // the list of candidate names.

        for (String candidate in candidateNames) {
          final match = authorsMap.entries.where((entry) => entry.value == candidate).firstOrNull;

          if (match != null) {
            matchedAuthorId = match.key;
            break;
          } 
        }

        if (matchedAuthorId != null) {
          debugPrint("Adding matchedAuthorId: $matchedAuthorId");
          processAuthorIds.add(matchedAuthorId);
        } else {
          final nameParts = splitFullName(personalName);

          var newAuthorData = {
            "author_f_name" : nameParts['firstName'],
            "author_l_name" : nameParts['lastName'],
            "openlibrary_key" : authorPath,
            "alternate_names" : candidateNames,
          };

          final insertResponse = await supabase
            .from('author_tab')
            .insert(newAuthorData)
            .select('author_id')
            .single();

          String newId = insertResponse['author_id'] as String;
          authorsMap[newId] = '${nameParts['firstName']} ${nameParts['lastName']}';

          // Add new ID to our result list
          processAuthorIds.add(newId);
        }
      } else {
          // Handle API errors.
        debugPrint("OpenLibrary API error: ${response.statusCode} for key $authorPath");
      }
    } catch (error) {
      // Handles internet connection error, JSON parsing faileures or Supabase crashes.
      debugPrint("Failed to obtain author ids: $error");
      return null;
    }
  } // Terminated looping over the authors.

  return processAuthorIds;
}

/// Given a list of publisher names, sees if they are present in the database and
/// eventually returns their pub_id. If they are not present, it adds them to the
/// database and returns the new id.
Future<List<String>?> getPublisherID({required List<dynamic> publishers}) async {
  final supabase = Supabase.instance.client;
  List<String> processedPublisherIds = []; 

  try {
    final PostgrestList res = await supabase
        .from('publisher_tab')
        .select('pub_id, pub_name');

    // Store the ID as the key, and the NORMALIZED name as the value for easy matching
    Map<String, String> normalizedPublishersMap = {
      for (var pub in res)
        pub['pub_id'] as String: normalizePublisherName(pub['pub_name'] as String)
    };

    for (String originalName in publishers) {
      if (originalName.trim().isEmpty) continue;

      // Normalize the incoming name
      final targetNormalizedName = normalizePublisherName(originalName);

      // Search the map using the normalized names
      final match = normalizedPublishersMap.entries
          .where((entry) => entry.value == targetNormalizedName)
          .firstOrNull;

      if (match != null) {
        processedPublisherIds.add(match.key);
      } else {
        var newPublisherData = {
          // Save the original, correctly-capitalized name to the database
          "pub_name": originalName.trim(), 
        };

        final insertResponse = await supabase
            .from('publisher_tab')
            .insert(newPublisherData)
            .select('pub_id')
            .single();

        String newId = insertResponse['publisher_id'] as String;

        // Add the NORMALIZED name to the local map to catch duplicates in the same batch
        normalizedPublishersMap[newId] = targetNormalizedName;

        processedPublisherIds.add(newId);
      }
    }
  } catch (error) {
    debugPrint("Failed to process publishers: $error");
  }

  return processedPublisherIds;
}

/// Allows manual insertion of a book to the catalog.
Future<bool> manualInsertion(Map<String, dynamic> book) async {
  throw UnimplementedError(); 
}

/// Gets missing info when ISBN is not directly found on OL catalog.
Future<Map<String, dynamic>> getMissingInfo(Map<String, dynamic> book) {
  throw UnimplementedError();
}
