import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {

  final Future<List<String>> Function(String query) onSearch;

  const SearchScreen({
    super.key,
    required this.onSearch,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}


class _SearchScreenState extends State<SearchScreen> {

  final List<String> _temporaryBookList = [
    "Moby Dick",
    "1984",
    "Nexus",
  ];

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("This is the search result page.")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SearchAnchor(
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
              leading: const Icon(Icons.search),
            );
          }, 
          suggestionsBuilder: (BuildContext context, SearchController controller) async {
            final String searchInput = controller.text.toLowerCase();

            // Call the search function passed from the parent widget
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
                onTap: () {
                  setState(() {
                    controller.closeView(book);
                  });
                }
              );
            }).toList();

            final filteredResults = _temporaryBookList
              .where((book) => book.toLowerCase().contains(searchInput)).toList();

            if (filteredResults.isEmpty) {
              return [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No matching books found')),
                )
              ];
            }

            return filteredResults.map((book) {
              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(book),
                onTap: (){
                  setState(() {
                    controller.closeView(book);
                  });
                });
            }).toList();
          }, 
        )
      )
    );
  }
}