import 'package:flutter/material.dart';
import 'package:pettebook/bookdetailpage.dart';
import 'package:pettebook/components.dart';
import 'package:pettebook/searchscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pettebook/datafetching.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late Future<List<Map<String, dynamic>>> _booksFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _booksFuture = _getBooksFromSupabase();
  }  

  Future<List<Map<String, dynamic>>> _getBooksFromSupabase() async {
    final response = await supabase.from('book_tab').select();

    return List<Map<String, dynamic>>.from(response);
  }


  Widget buildCard(Map<String, dynamic> book) {
    final String title = book['title'] ?? 'Untitled';
    final String author = book['author'] ?? 'Unknown Author';

    final String? isbn = book['isbn'];

    final String imageUrl = isbn != null && isbn.isNotEmpty
      ? 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg'
      : '';

    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ), 
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          hoverColor: Colors.blue.withValues(alpha: 0.05),
          splashColor: Colors.blue.withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => InternalBookDetailScreen(book: book)
              )
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return buildImagePlaceholder();
                        },
                      )
                    : buildImagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pettena's Library")),
      body: Padding(
        padding: const .all(8.0),
        child: Column(
          children: [
            MySearchBar(
                targetSearchScreenBuilder: (context) => SearchScreen(
                  onSearch: (query) => supabaseSearch(query),
                ),
                hintText: "Type to search catalog..."
            ),
            const SizedBox(height: 16),
            const Text(
              "Random book generator",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 200,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _booksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting){
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final books = snapshot.data ?? [];
                  if (books.isEmpty) {
                    return const Center(child: Text('No books found in yourr library.'));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];

                      return Padding(
                        padding: const EdgeInsets.only(right:  12.0),
                        child: buildCard(book),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Other people are reading...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 150,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _booksFuture,
                builder: (context, snapshot) {
                
                final books = snapshot.data ?? [];

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];

                      return Padding(
                        padding: const EdgeInsets.only(right:  12.0),
                        child: buildCard(book),
                      );
                    },
                  );
                }
              ),
            )
          ],
        ),
      )
    );
  }
}