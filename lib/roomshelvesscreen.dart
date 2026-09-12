import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class RoomShelvesPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String householdId;

  const RoomShelvesPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.householdId,
  });

  @override
  State<RoomShelvesPage> createState() => _RoomShelvesPageState();
}

class _RoomShelvesPageState extends State<RoomShelvesPage> {
  late Future<List<Map<String, dynamic>>> _shelvesFuture;

  @override
  void initState() {
    super.initState();
    _shelvesFuture = _fetchShelves();
  }

  Future<List<Map<String, dynamic>>> _fetchShelves() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
      .from('bookshelf_tab')
      .select('shelf_id, shelf_name')
      .eq('room_id', widget.roomId)
      .order('shelf_name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
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
                          _shelvesFuture = _fetchShelves(); 
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

  Future<void> _handleRemoveShelf(String shelfId, String shelfName) async {
    final supabase = Supabase.instance.client;

    final booksResponse = await supabase
      .from('book_tab')
      .select('book_id')
      .eq('shelf_id', shelfId);

    final bookCount = booksResponse.length;

    if (bookCount == 0) {
      await supabase.from('bookshelf_tab').delete().eq('shelf_id', shelfId);
      setState(() {
        _shelvesFuture = _fetchShelves();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$shelfName deleted.")),
        );
      }
      return;
    }

    if (!mounted) return;

    final alternativeShelves = await supabase
      .from('bookshelf_tab')
      .select('shelf_id, shelf_name, room_tab(room_name)')
      .eq('household_id', widget.householdId)
      .neq('shelf_id', shelfId)
      .order('shelf_name', ascending: true);

    if(!mounted) return;

    String? selectedTargetShelfId;
    bool isMigrating = false;

    await showDialog(
      context: context, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Delete Shelf"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "'$shelfName' contains $bookCount books. Where would you like to move them?", 
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: "Destination",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedTargetShelfId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("Leave Unassigned"),
                      ),

                      ...alternativeShelves.map((shelf) {
                        final roomName = shelf['room_tab']['room_name'];
                        return DropdownMenuItem(
                          value: shelf['shelf_id'].toString(),
                          child: Text("${shelf['shelf_name']} ($roomName)"),
                        );
                      }),
                    ], 
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTargetShelfId = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isMigrating ? null : () => Navigator.pop(context), 
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: isMigrating ? null : () async {
                    setDialogState(() => isMigrating = true);

                    try {
                      if (selectedTargetShelfId != null) {
                        await supabase
                          .from('book_tab')
                          .update({'shelf_id': selectedTargetShelfId})
                          .eq('shelf_id', shelfId);
                      }

                      // If the selected target shelf id is null, we do nothing
                      // because it is handled by the ON DELETE SET NULL constraint
                      // automatically

                      await supabase
                        .from('bookshelf_tab')
                        .delete()
                        .eq('shelf_id', shelfId);
                    
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _shelvesFuture = _fetchShelves();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Shelf deleted and books moved."))
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isMigrating = false);
                      debugPrint("Error migrating books: $e");
                    }
                  }, 
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: isMigrating ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeAlign: 2),
                  ) : const Text("Delete"),
                )
              ],
            );
          },
        );
      } 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.roomName} Shelves")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shelvesFuture, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading shelves: ${snapshot.error}"),
            );
          }

          final shelves = snapshot.data;
          if (shelves == null || shelves.isEmpty) {
            return const Center(child: Text("No shelves found in this room."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: shelves.length,
            itemBuilder: (context, index) {
              final shelf = shelves[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  title: Text(
                    shelf['shelf_name'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          debugPrint("Pressed 'Rename' Button");
                        }, 
                        style: ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll<Color?>(Colors.lightBlue),
                        ),
                        child: const Text("Rename"),
                      ),
                      TextButton(
                        onPressed: () {
                          debugPrint("Pressed 'Change Room' Button");
                        }, 
                        style: ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll<Color?>(Colors.lightBlue),
                        ),
                        child: const Text("Change Room"),
                      ),
                      IconButton(
                        onPressed: () {
                          _handleRemoveShelf(
                            shelf['shelf_id'].toString(), 
                            shelf['shelf_name'].toString()
                          );
                        }, 
                        style: ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll<Color?>(Colors.lightBlue),
                        ),
                        icon: Icon(Icons.delete, color: Colors.red,),
                      ),
                    ],
                  ),
                  onTap: () {
                    debugPrint("Tapped on shelf: ${shelf['shelf_name']}");
                  },
                ),
              );
            }
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddShelfDialog(context),
        tooltip: "Add Shelf",
        child: const Icon(Icons.add),
      ),
    );
  }
}