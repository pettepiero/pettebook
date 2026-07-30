import 'package:flutter/material.dart';
import 'package:pettebook/bookdetailpage.dart';


class SearchScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String query) onSearch;
  final bool isLiveSearch;
  const SearchScreen({
    super.key,
    required this.onSearch,
    this.isLiveSearch = true,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchController _liveSearchController = SearchController();
  final TextEditingController _submitSearchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _submitSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    final List<Map<String, dynamic>> results = await widget.onSearch(query);
    debugPrint("\nIn _SearchScreenState: results: $results");

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _liveSearchController.dispose();
    _submitSearchController.dispose();
    super.dispose();
  }

  Widget _buildLiveSearch() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SearchAnchor(
        searchController: _liveSearchController,
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            onTap: () => controller.openView(),
            onChanged: (text) {
              if (text.isNotEmpty && !controller.isOpen) {
                controller.openView();
              }
            },
            leading: const Icon(Icons.search),
          );
        },
        suggestionsBuilder: (BuildContext context, SearchController controller) async {
          final String searchInput = controller.text.toLowerCase();
          if (searchInput.isEmpty) return [];

          final List<Map<String, dynamic>> results = await widget.onSearch(searchInput);

          if (results.isEmpty) {
            return [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No matching books found')),
              )
            ];
          }
          return results.map((book) {
            return ListTile(
              leading: const Icon(Icons.book),
              title: Text(book['title']?.toString() ?? 'Unknown Title'),
              subtitle: Text(book['authors']?.toString() ?? 'Unknown Author'),
              dense: true,
              onTap: () {
              },
            );
          }).toList();
        },
      )
    );
  }

  Widget _buildSubmitOnlySearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SearchBar(
            controller: _submitSearchController,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),

            onSubmitted: (text) => _submitSearch(text),
            leading: const Icon(Icons.search),
          ),
        ),

        Expanded(
          child: _buildResultsBody(),
        ),
      ],
    );
  }

  Widget _buildResultsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const Center(child: Text('Type a book title and press enter to search.'));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('No matching books found.'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.book),
          title: Text(book['title']?.toString() ?? 'Unknown Title'),
          subtitle: Text(book['authors']?.toString() ?? 'Unknown Author'),
          onTap: () {
            debugPrint('Selected: $book');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ExternalBookDetailScreen(book: book)
                ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("This is the search result page.")),
      body: widget.isLiveSearch ? _buildLiveSearch() : _buildSubmitOnlySearch(),
    );
  }
}