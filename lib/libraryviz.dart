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
	final Function(Map<String, dynamic> shelf, BuildContext context)? onShelfSelected;

	final bool isManageMode;

	const GenericShelvesPage({
		super.key,
		required this.roomId,
		required this.roomName,
		required this.householdId,
		required this.pageTitle,
		this.onShelfSelected,
		this.isManageMode = false,
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

  Future<void> _showEditShelfDialog(BuildContext context, Map<String, dynamic> shelf) async {
    final TextEditingController nameController = TextEditingController();
    final supabase = Supabase.instance.client;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            return SimpleDialog(
              title: const Text("Edit shelf"),
             	children: <Widget>[
								SimpleDialogOption(
									onPressed: () {
											Navigator.pop(dialogContext);
											_renameShelfDialog(context, shelf);
									},
									child: const Text("Rename shelf"),
								),
								SimpleDialogOption(
									onPressed: () {debugPrint("Chose to move shelf");},
									child: const Text("Move to another room"),
								),
								SimpleDialogOption(
									onPressed: () {debugPrint("Chose to delete shelf");},
									child: const Text("Delete shelf"),
								),
								SimpleDialogOption(
									onPressed: () {debugPrint("Chose to delete shelf and its contained books");},
									child: const Text("Delete shelf and its contained books"),
								),
							],
            );
          },
        );
      },
    );
  }



  Future<void> _renameShelfDialog(BuildContext context, Map<String, dynamic> shelf) async {
    final TextEditingController nameController = TextEditingController();
    final supabase = Supabase.instance.client;
    String? errorMessage;

    await showDialog(
      context: context,
			barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Rename Shelf"),
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
											debugPrint("\n\n shelf: $shelf");
                      await supabase
												.from('bookshelf_tab')
												.update({'shelf_name': newShelfName})
												.eq('shelf_id', shelf['shelf_id']);

                      debugPrint("Shelf renamed successfully!");

                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _shelvesFuture = fetchShelves(widget.roomId);  //Unsure about what to do here
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Renamed to $newShelfName")),
                        );
                      }
                    } on PostgrestException catch (error) {
                      if (error.code == '23505') {
                        debugPrint("A shelf with this name already exists in this room.");
                      } else {
                        debugPrint("A database error occurred in rearrangeroomsscreen.dart: ${error.message}");
                      }
                    } catch (e) {
                      debugPrint("An unexpected error occurred: $e");
                    }
                  },  
                  child: const Text("Rename")
                ),
              ],
            );
          },
        );
      },
    );
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
								debugPrint("Found shelves: $shelves");
								debugPrint("snapshot: $snapshot");
								final filteredShelves= shelves.where((shelf) {
									final name = shelf['shelf_name'].toString().toLowerCase();
									return name.contains(_searchQuery);
								}).toList();

								return ShelfList(
									shelves: filteredShelves,
									onShelfSelected: (shelf) {
										if (widget.isManageMode) {
											_showEditShelfDialog(context, shelf);
										} else if (widget.onShelfSelected != null) {
											widget.onShelfSelected!(shelf, context);
										}
									} 
								); //ShelfList
							}, //Expanded.builder
						), //FutureBuilder
					), // Expanded
				], //Children
			), //Column
      floatingActionButton: widget.isManageMode
				? FloatingActionButton(
					onPressed: () => _showAddShelfDialog(context),
					child: const Icon(Icons.add),
					)
				: null,
		); //Scaffold
	} //Widget.build
}

