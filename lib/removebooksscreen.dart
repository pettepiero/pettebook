import 'package:flutter/material.dart';
import 'package:pettebook/datafetching.dart';
import 'package:pettebook/searchscreen.dart';
import 'package:pettebook/components.dart';
import 'package:pettebook/rearrangeroomsscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pettebook/libraryviz.dart';


class RemoveBooksRoomPage extends StatefulWidget {
	const RemoveBooksRoomPage({super.key});

  @override
  State<RemoveBooksRoomPage> createState() => _RemoveBooksRoomPageState();
}

class _RemoveBooksRoomPageState extends State<RemoveBooksRoomPage> {
	late Future<List<Map<String, dynamic>>> _roomsFuture;
  final TextEditingController _searchController = TextEditingController();
	String _searchQuery = '';

  @override
  void initState() {
    super.initState();
		_roomsFuture = fetchRooms();
  }

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text("Select room to remove books from")),
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(16.0),
						child: TextField(
							controller: _searchController,
							decoration: InputDecoration(
								hintText: 'Search rooms...',
								prefixIcon: const Icon(Icons.search),
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),),
								suffixIcon: _searchQuery.isNotEmpty
									? IconButton(
											icon: const Icon(Icons.clear),
											onPressed: () {
												_searchController.clear();
												setState(() => _searchQuery = '');
											},
										)
									: null,
							), //InputDecoration							
							onChanged: (value) {
								setState(() {
									_searchQuery = value.toLowerCase();
								});
							},
						), //TextField
					), //Padding
				
					Expanded(
						child: FutureBuilder<List<Map<String, dynamic>>>(
							future: _roomsFuture,
							builder: (context, snapshot) {
								if (snapshot.connectionState == ConnectionState.waiting) {
									return const Center(child: CircularProgressIndicator());
								}
								if (snapshot.hasError) {
									return Center(child: Text("Error: ${snapshot.error}"));
								}

								final rooms = snapshot.data ?? [];
								final filteredRooms = rooms.where((room) {
									final name = room['room_name'].toString().toLowerCase();
									return name.contains(_searchQuery);
								}).toList();

								return RoomGrid(
									rooms: filteredRooms,
									onRoomSelected: (room) {
										Navigator.push(
											context,
											MaterialPageRoute(
												builder: (context) => GenericShelvesPage(
													roomId: room['room_id'].toString(),
													roomName: room['room_name'].toString(),
													householdId: room['household_id'].toString(),
													pageTitle: "Select to remove books",
													onShelfSelected: (shelf, context) {
														Navigator.push(
															context,
															MaterialPageRoute(
																builder: (context) => RemoveBooksBooksPage(
																	shelfId: shelf['shelf_id'].toString(),
																	shelfName: shelf['shelf_name'].toString(),
																	householdId: shelf['household_id'].toString(),
																),
															),
														);
													},
												), //ShelvesPage
											), //MaterialPageRoute
										);
									},
								); //RoomGrid
							}, //Expanded.builder
						), //FutureBuilder
					), // Expanded
				], //Children
			), //Column
		); //Scaffold
	} //Widget.build
} //_RemoveBookRoomPageState

class RemoveBooksBooksPage extends StatefulWidget {
	final String shelfId;
	final String shelfName;
	final String householdId;
	const RemoveBooksBooksPage({
		super.key, 
		required String this.shelfId,
		required String this.shelfName,
		required String this.householdId
	});

  @override
  State<RemoveBooksBooksPage> createState() => _RemoveBooksBooksPageState();
}

class _RemoveBooksBooksPageState extends State<RemoveBooksBooksPage> {
	late Future<List<Map<String, dynamic>>> _booksFuture;
  final TextEditingController _searchController = TextEditingController();
	String _searchQuery = '';

  @override
  void initState() {
    super.initState();
		_booksFuture = fetchBooks(widget.shelfId);
  }

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text("Select books to remove from library")),
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(16.0),
						child: TextField(
							controller: _searchController,
							decoration: InputDecoration(
								hintText: 'Search books...',
								prefixIcon: const Icon(Icons.search),
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),),
								suffixIcon: _searchQuery.isNotEmpty
									? IconButton(
											icon: const Icon(Icons.clear),
											onPressed: () {
												_searchController.clear();
												setState(() => _searchQuery = '');
											},
										)
									: null,
							), //InputDecoration							
							onChanged: (value) {
								setState(() {
									_searchQuery = value.toLowerCase();
								});
							},
						), //TextField
					), //Padding
				
					Expanded(
						child: FutureBuilder<List<Map<String, dynamic>>>(
							future: _booksFuture,
							builder: (context, snapshot) {
								if (snapshot.connectionState == ConnectionState.waiting) {
									return const Center(child: CircularProgressIndicator());
								}
								if (snapshot.hasError) {
									return Center(child: Text("Error: ${snapshot.error}"));
								}

								final books = snapshot.data ?? [];
								final filteredBooks = books.where((book) {
									final name = book['title'].toString().toLowerCase();
									return name.contains(_searchQuery);
								}).toList();

								return BookList(
									books: filteredBooks,
									onBookSelected: (book) async {
  									final supabase = Supabase.instance.client;
										final bookId = book['book_id'];
  									final response = await supabase
  									  .from('book_tab')
  									  .delete()
  									  .eq('book_id', bookId);
									},
								); //ShelfGrid
							}, //Expanded.builder
						), //FutureBuilder
					), // Expanded
				], //Children
			), //Column
		); //Scaffold
	} //Widget.build
} //_RemoveBookShelfPageState
