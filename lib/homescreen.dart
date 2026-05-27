import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<String> _temporaryBookList = [
    "Moby Dick",
    "1984",
    "Nexus",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pettena's Library")),
      body: Padding(
        padding: const .all(8.0),
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
                if (text.isNotEmpty && !controller.isOpen){
                controller.openView();
                }
              },
              leading: const Icon(Icons.search),
              hintText: 'Start typing to search books...',
              );
          }, 
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            final String searchInput = controller.text.toLowerCase();

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
        ),
      ),
    );
  }
}