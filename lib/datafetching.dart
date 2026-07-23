import 'package:open_library/open_library.dart'

class BookRepository {
  final List<String> _localCatalog = ["Moby Dick", "1984", "Nexus"];

  Future<List<String>> searchLocalCatalog(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lowerQuery = query.toLowerCase();
    return _localCatalog
        .where((book) => book.toLowerCase().contains(lowerQuery))
        .toList();
  }

  //Future<List<String>> searchOnlineApi(String query) async {
  //  try {

  //  }
  //}

}