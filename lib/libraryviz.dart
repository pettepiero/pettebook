import 'package:flutter/material.dart';
import 'package:pettebook/datafetching.dart';
import 'package:pettebook/components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
	final bool showAddButton;

	const GenericShelvesPage({
		super.key,
		required this.roomId,
		required this.roomName,
		required this.householdId,
		required this.pageTitle,
		required this.onShelfSelected,
		this.showAddButton = false,
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

  Future<void> _showAddShelfDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final supabase = Supabase.instance.client;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Shelf"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Shelf Name",
                      hintText: "e.g. Wooden Shelf",
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () async {
                    final newShelfName = nameController.text.trim();
                    if (newShelfName.isEmpty) return;

                    setDialogState(
                      () => errorMessage = null,
                    );

                    // Check if the shelf already exists in this room or in general
                    // if this household has a shelf with the same name 
                    try {
                      await supabase.from('bookshelf_tab').insert({
                        'shelf_name': newShelfName,
                        'room_id': widget.roomId,
                        'household_id': widget.householdId,
                      });

                      debugPrint("Shelf added successfully!");

                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _shelvesFuture = fetchShelves(widget.roomId); 
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Added $newShelfName")),
                        );
                      }
                    } on PostgrestException catch (error) {
                      if (error.code == '23505') {
                        debugPrint("A shelf with this name already exists in this room.");
                      } else {
                        debugPrint("A database error occurred: ${error.message}");
                      }
                    } catch (e) {
                      debugPrint("An unexpected error occurred: $e");
                    }
                  },  
                  child: const Text("Save")
                ),
              ],
            );
          },
        );
      },
    );
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
      floatingActionButton: widget.showAddButton
				? FloatingActionButton(
					onPressed: () => _showAddShelfDialog(context),
					child: const Icon(Icons.add),
					)
				: null,
		); //Scaffold
	} //Widget.build
}

