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
                  trailing: const Icon(Icons.chevron_right),
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