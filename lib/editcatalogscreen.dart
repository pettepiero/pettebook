import 'package:flutter/material.dart';
import 'rearrangeshelvesscreen.dart';
import 'scanormanual.dart';

class EditCatalogScreen extends StatefulWidget {
  const EditCatalogScreen({super.key});

  @override
  State<EditCatalogScreen> createState() => _EditCatalogScreenState();
}

class _EditCatalogScreenState extends State<EditCatalogScreen> {
  final List<GridItemData> _gridItems = [
    // GridItemData(title: "Add Books", color: Colors.teal[100]!, icon: Icon(Icons.add_circle_outlined),targetPage: const AddBooksPage()),
    GridItemData(title: "Add Books", color: Colors.teal[100]!, icon: Icon(Icons.add_circle_outlined),targetPage: const ScanOrManualScreen()),
    GridItemData(title: "Remove Books", color: Colors.teal[200]!, icon: Icon(Icons.remove_circle_outlined), targetPage: const RemoveBooksPage()),
    GridItemData(title: "Rearrange Shelves", color: Colors.teal[300]!, icon: Icon(Icons.swap_calls_outlined), targetPage: const RearrangeShelvesPage()),
    GridItemData(title: "Edit Books", color: Colors.teal[400]!, icon: Icon(Icons.edit_outlined), targetPage: const EditBooksPage()),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Catalog"), centerTitle: true,),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GridView.builder(
                primary: false,
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                ),
                itemCount: _gridItems.length,
                itemBuilder: (context, index){
                  final item = _gridItems[index];
                  
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => item.targetPage),
                      );
                    },
                    splashColor: Colors.black12,
                    child: Ink(
                      padding: const EdgeInsets.all(8),
                      color: item.color,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: item.icon,
                                    ),
                                ),
                              ),
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                              const SizedBox(height: 20.0),
                            ]
                        ),
                      ),
                    ),
                  );
                },
              ),
          )
        )
      )
    );
  }
}

class GridItemData {
  final String title;
  final Color color;
  final Widget icon;
  final Widget targetPage;

  const GridItemData({
    required this.title,
    required this.color,
    required this.icon,
    required this.targetPage,
  });
}


class AddBooksPage extends StatelessWidget {const AddBooksPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Add Books")),);}
class RemoveBooksPage extends StatelessWidget {const RemoveBooksPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Remove Books")),);}
class EditBooksPage extends StatelessWidget {const EditBooksPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Edit Books")),);}
