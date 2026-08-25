import 'package:flutter/material.dart';
import 'package:pettebook/components.dart';
import 'package:pettebook/datafetching.dart';

Widget getCover({required Map<String, dynamic> book}){
//Image getCover(Map<String, dynamic> book) {
  final String? coverId = book['cover_id'];
  final String? isbn = book['isbn'];
  String imageUrl = '';
  if (coverId != null && coverId.isNotEmpty){
    imageUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
  } else if (isbn != null && isbn.isNotEmpty){
    imageUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
  }

  if (imageUrl.isNotEmpty) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace){
        return buildImagePlaceholder();
      },
    );
  }
  return buildImagePlaceholder();
}

class ExternalBookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  const ExternalBookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {

    //Get the image of the book cover here
    //final String? coverId = book['cover_id'];
    //final String? isbn = book['isbn'];
    final String workKey = book['workKey'];

    final Future<List<Map<String, dynamic>>> isbnList = fetchEditionsFromWork(workKey);

    //String imageUrl = '';

    //if (coverId != null && coverId.isNotEmpty){
    //  imageUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    //} else if (isbn != null && isbn.isNotEmpty){
    //  imageUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
    //}
    Widget cover = getCover(book: book);

    return Scaffold(
      appBar: AppBar(
        title: Text("Book Page"),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height*0.45,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4, 
                    child: cover,
                  ),
                  const SizedBox(width: 16,), // spacing between image and text

                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title']?.toString() ?? "Unknown Title",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book['authors']?.toString() ?? "Unknown Author",
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Year: ${book['year']?.toString() ?? "Unknown Year"}"
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Publisher: ${book['pub']?.toString() ?? "Unknown Publisher"}"
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ISBN: ${book['isbn']?.toString() ?? "Unknown ISBN"}"
                          ),
                        ],
                      )
                    ),
                  )
                ],
              ),
            ),
          ),

          const Divider(thickness: 2),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Available Editions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ),

          Expanded(
              child: workKey.isEmpty
                  ? const Center(child: Text("No edition data available for this work."))
                  : FutureBuilder<List<Map<String, dynamic>>>(
                future: isbnList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading editions: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No other editions found."));
                  }
                  final editions = snapshot.data;

                  return ListView.builder(
                    itemCount: editions!.length, //already checked it has data
                    itemBuilder: (context, index) {
                      final edition = editions[index];
                      final editionIsbn = edition['isbn']?.toString() ?? '';
                      final editionPub = edition['pub']?.toString() ?? 'Unknown Publisher';
                      final editionYear = edition['year']?.toString() ?? 'Unknown Year';
                      final displayIsbn = editionIsbn.isNotEmpty ? editionIsbn : "No ISBN provided";
                      
                      Widget cover = getCover(book: edition);

                      return ListTile(
                        //leading: const Icon(Icons.library_books),
                        leading: SizedBox(
                          width: 20,
                          height: 30,
                          child: cover,
                        ),
                        title: Text("ISBN: $displayIsbn"),
                        subtitle: Text("$editionPub ($editionYear)"),
                        trailing: TextButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStatePropertyAll<Color?>(Colors.lightBlue),
                              ),
                            child: const Text("Add to library"),
                            onPressed: () async {
                              addToLibrary(book);
                            }
                        ),
                      );
                    },

                  );
                },
              )
          )
        ],
      )
    );
  }
}

class InternalBookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  const InternalBookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {

    //Get the image of the book cover here
    //final String? coverId = book['cover_id'];
    //final String? isbn = book['isbn'];

    //final String workKey = book['workKey'];

    Widget cover = getCover(book: book);

    return Scaffold(
      appBar: AppBar(
        title: Text("Book Page"),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height*0.45,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4, 
                    child: cover,
                  ),
                  const SizedBox(width: 16,), // spacing between image and text

                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title']?.toString() ?? "Unknown Title",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book['authors']?.toString() ?? "Unknown Author",
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Year: ${book['year']?.toString() ?? "Unknown Year"}"
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Publisher: ${book['pub']?.toString() ?? "Unknown Publisher"}"
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ISBN: ${book['isbn']?.toString() ?? "Unknown ISBN"}"
                          ),
                          Text(
                            "Location: ${book['location']?.toString() ?? "Unknown Location"}"
                          ),
                        ],
                      )
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      )
    );
  }
}
