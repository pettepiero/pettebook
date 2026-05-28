import 'package:flutter/material.dart';
import 'package:pettebook/searchscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pettena's Library")),
      body: Padding(
        padding: const .all(8.0),
        child: Column(
          children: [
            SearchBar(
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              leading: const Icon(Icons.search),
              hintText: 'Start typing to search books...',
            ),
            const SizedBox(height: 16),
            Expanded(
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
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];

                      final String title = book['title'] ?? 'Unknown Title';
                      final String author = book['author'] ?? 'Unknown Author';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: const Icon(Icons.book, color: Colors.deepPurple),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(author),
                          onTap: () {

                          },
                        )
                      );
                    }
                  );
                },
              ))
          ],

        )
        
      )
    );
  }
}