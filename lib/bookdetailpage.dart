import 'package:flutter/material.dart';
import 'package:pettebook/components.dart';

class ExternalBookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  const ExternalBookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {

    //Get the image of the book cover here
    final String? coverId = book['cover_id'];
    final String? isbn = book['isbn'];

    String imageUrl = '';

    if (coverId != null && coverId.isNotEmpty){
      imageUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    } else if (isbn != null && isbn.isNotEmpty){
      imageUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
    }

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
                    child: imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, StackTrace){
                          return buildImagePlaceholder();
                        },
                      )
                      : buildImagePlaceholder(),
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
              )
            )
          )
        ],
      )
    );
  }
}
