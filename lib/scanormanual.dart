import 'package:flutter/material.dart';
import 'package:pettebook/editcatalogscreen.dart';
import 'package:pettebook/searchscreen.dart';
import 'package:pettebook/datafetching.dart';


List<String> myBooks = ['1984', 'Dune', 'Narnia'];

class ScanOrManualScreen extends StatefulWidget {
  void debugprinter() {
    print('Inside scan or manual screen');
  }
  const ScanOrManualScreen({super.key});

  @override
  State<ScanOrManualScreen> createState() => _ScanOrManualScreenState();
}

class _ScanOrManualScreenState extends State<ScanOrManualScreen> {

  @override
  Widget build(BuildContext context) {

    final List<GridItemData> _gridItems = [
      GridItemData(
          title: "Scan ISBN",
          color: Colors.teal[100]!,
          icon: Icon(Icons.barcode_reader),
          targetPage: const BarCodeReaderScreen()
      ),
      GridItemData(
        title: "Manual Entry",
        color: Colors.teal[200]!,
        icon: Icon(Icons.search),
        targetPage: SearchScreen(
          onSearch: (query) => openlibrarySearch(query, context),
          isLiveSearch: false,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Choose how you want to add books."), centerTitle: true,),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _gridItems.length,
                itemBuilder: (context, index) {
                  final item = _gridItems[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                          item.targetPage)
                      );
                    },
                    splashColor: Colors.black12,
                    child: Ink(
                        padding: const EdgeInsets.all(8.0),
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                                const SizedBox(height: 20.0),
                              ]
                          ),
                        )
                    ),
                  );
                },
            ),
          )
        )
      ),
    );
  }
}


class BarCodeReaderScreen extends StatelessWidget {const BarCodeReaderScreen({super.key}); @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan ISBN of desired book."), centerTitle: true,),
    );
  }
}

//class ManualEntryScreen extends StatelessWidget {const ManualEntryScreen({super.key}); @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: Text("Manual search of desired book."), centerTitle: true,),
//      body: Padding(
//        padding: const .all(8.0),
//        child: MySearchBar(
//            targetSearchScreenBuilder: (context) => SearchScreen(
//              onSearch: (query) => openlibrarySearch(query, context),
//              isLiveSearch: false,
//            ),
//            hintText: 'Type book here...',
//        )
//      ),
//    );
//  }
//}
