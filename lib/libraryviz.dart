import 'package:flutter/material.dart';
import 'package:pettebook/datafetching.dart';
import 'package:pettebook/components.dart';

class GenericRoomPage extends StatefulWidget {
	final String householdId;
	final String pageTitle;
	final Function(Map<String, dynamic> book, BuildContext context) onRoomSelected;
	const GenericRoomPage({
		super.key,
		required this.householdId,
		required this.pageTitle,
		required this.onRoomSelected,
	});

  @override
  State<GenericRoomPage> createState() => _GenericRoomPageState();
}

class _GenericRoomPageState extends State<GenericRoomPage> {
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
			appBar: AppBar(title: Text(widget.pageTitle)),
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
									onRoomSelected: (room) => widget.onRoomSelected(room, context),//{
										//Navigator.push(
										//	context,
										//	MaterialPageRoute(
										//		builder: (context) => RemoveBooksShelvesPage(
										//			roomId: room['room_id'].toString(),
										//			roomName: room['room_name'].toString(),
										//			householdId: room['household_id'].toString(),
										//		), //RemoveBooksShelvesPage
										//	), //MaterialPageRoute
										//);
									//},
								); //RoomGrid
							}, //Expanded.builder
						), //FutureBuilder
					), // Expanded
				], //Children
			), //Column
		); //Scaffold
	} //Widget.build
} //_RemoveBookRoomPageState


class GenericShelvesPage extends StatefulWidget {
	final String roomId;
	final String roomName;
	final String householdId;
	final String pageTitle;
	final Function(Map<String, dynamic> shelf, BuildContext context) onShelfSelected;

	const GenericShelvesPage({
		super.key,
		required this.roomId,
		required this.roomName,
		required this.householdId,
		required this.pageTitle,
		required this.onShelfSelected,
	});

	@override
	State<GenericShelvesPage> createState() => _GenericShelvesPageState();
}

class _GenericShelvesPageState extends State<GenericShelvesPage> {
	late Future<List<Map<String, dynamic>>> _shelvesFuture;
	final TextEditingController _searchController = TextEditingController();
	String _searchQuery = '';

  @override
  void initState() {
    super.initState();
		_shelvesFuture = fetchShelves(widget.roomId);
  }

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text(widget.pageTitle)),
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(16.0),
						child: TextField(
							controller: _searchController,
							decoration: InputDecoration(
								hintText: 'Search shelves...',
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
							future: _shelvesFuture,
							builder: (context, snapshot) {
								if (snapshot.connectionState == ConnectionState.waiting) {
									return const Center(child: CircularProgressIndicator());
								}
								if (snapshot.hasError) {
									return Center(child: Text("Error: ${snapshot.error}"));
								}

								final shelves = snapshot.data ?? [];
								final filteredShelves= shelves.where((shelf) {
									final name = shelf['shelf_name'].toString().toLowerCase();
									return name.contains(_searchQuery);
								}).toList();

								return ShelfList(
									shelves: filteredShelves,
									onShelfSelected: (shelf) => widget.onShelfSelected(shelf, context),
								); //ShelfList
							}, //Expanded.builder
						), //FutureBuilder
					), // Expanded
				], //Children
			), //Column
		); //Scaffold
	} //Widget.build
}

