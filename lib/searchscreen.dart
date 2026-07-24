import 'package:flutter/material.dart';


class SearchStateData {
  final bool isLoading;
  final List<String>? results;

  SearchStateData({this.isLoading = false, this.results});
}

class SearchScreen extends StatefulWidget {
  final Future<List<String>> Function(String query) onSearch;
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
  final SearchController _searchController = SearchController();
  final ValueNotifier<SearchStateData> _searchState = ValueNotifier(SearchStateData());

  //List<String> _searchResults = [];
  //bool _isSearching = false;
  //bool _hasSearched = false;

  Future<void> _submitSearch(String query) async {
    if (widget.isLiveSearch || query.isEmpty) return;
    _searchState.value = SearchStateData(isLoading: true, results: null);

    if (!_searchController.isOpen) {
      _searchController.openView();
    }
    final List<String> results = await widget.onSearch(query);

    _searchState.value = SearchStateData(isLoading: false, results: results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("This is the search result page.")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SearchAnchor(
          searchController: _searchController,
          viewOnSubmitted: (text) => _submitSearch(text),
          builder: (BuildContext context, SearchController controller) {
            return SearchBar(
              controller: controller,
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onTap: () {
                controller.openView();
              },
              onChanged: (text) {
                if (text.isNotEmpty && !controller.isOpen) {
                  controller.openView();
                }
              },
              onSubmitted: (text) => _submitSearch(text),
              leading: const Icon(Icons.search),
            );
          }, 
          suggestionsBuilder: (BuildContext context, SearchController controller) async {
            final String searchInput = controller.text.toLowerCase();

            if (widget.isLiveSearch){
              final List<String> results = await widget.onSearch(searchInput);
              // handle empty state
              if (results.isEmpty) {
                return [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No matching books found')),
                  )
                ];
              }
              // Map results to widgets
              return results.map((book) {
                return ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(book),
                    onTap: () => controller.closeView(book),
                );
              }).toList();
            }
            else {

              return [
                ValueListenableBuilder<SearchStateData>(
                  valueListenable: _searchState,
                  builder: (context, state, _) {
                    if (state.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final results = state.results;

                    if (results == null) {
                      return const SizedBox.shrink();
                    }
                    if (results.isEmpty){
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No matching books found')),
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: results.map((book) {
                        return ListTile(
                          leading: const Icon(Icons.book),
                          title: Text(book),
                          onTap: () => controller.closeView(book),
                        );
                      }).toList(),
                    );
                  }
                )
              ];
            }
          },
        )
      )
    );
  }
}