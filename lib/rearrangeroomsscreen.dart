import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'roomshelvesscreen.dart';
import 'package:pettebook/datafetching.dart';
import 'package:pettebook/removebooksscreen.dart';
import 'package:pettebook/components.dart';
import 'package:pettebook/libraryviz.dart';

class RearrangeRoomsPage extends StatefulWidget {
  const RearrangeRoomsPage({super.key});

  @override
  State<RearrangeRoomsPage> createState() => _RearrangeRoomsPageState();
}

class _RearrangeRoomsPageState extends State<RearrangeRoomsPage> {
  late Future<List<Map<String, dynamic>>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = fetchRooms(); 
  }

  Future<void> _showAddRoomDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final supabase = Supabase.instance.client;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Room"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Room Name",
                      hintText: "e.g., Living Room",
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
                    final roomName = nameController.text.trim();
                    if (roomName.isEmpty) return;

                    setDialogState(
                      () => errorMessage = null,
                    ); // Clear previous errors

                    try {
                      // 1. Get the user's household_id
                      // (Assuming they only have one primary household for now)
                      final householdRes = await supabase
                          .from('household_member_tab')
                          .select('household_id')
                          .eq('user_id', supabase.auth.currentUser!.id)
                          .limit(1);

                      if (householdRes.isEmpty) {
                        setDialogState(
                          () => errorMessage =
                              "You do not belong to a household.",
                        );
                        return;
                      }

                      final householdId = householdRes.first['household_id'];

                      // 2. Check if the room already exists in THIS household (case-insensitive)
                      final existingRooms = await supabase
                          .from('room_tab')
                          .select('room_id')
                          .eq('household_id', householdId)
                          .ilike(
                            'room_name',
                            roomName,
                          ); // ilike ignores upper/lowercase differences

                      if (existingRooms.isNotEmpty) {
                        setDialogState(
                          () => errorMessage =
                              "A room with this name already exists.",
                        );
                        return;
                      }

                      // 3. Insert the new room
                      await supabase.from('room_tab').insert({
                        'room_name': roomName,
                        'household_id': householdId,
                      });

                      // 4. Close the dialog and refresh the grid
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _roomsFuture =
                              fetchRooms(); // Triggers the FutureBuilder to rebuild
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added $roomName')),
                        );
                      }
                    } catch (error) {
                      setDialogState(
                        () => errorMessage =
                            "Failed to add room. Please try again.",
                      );
                      debugPrint(error.toString());
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditShelfDialog(BuildContext context, Map<String, dynamic> shelf) async {
    final TextEditingController nameController = TextEditingController();
    final supabase = Supabase.instance.client;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Room"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Room Name",
                      hintText: "e.g., Living Room",
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
                    final roomName = nameController.text.trim();
                    if (roomName.isEmpty) return;

                    setDialogState(
                      () => errorMessage = null,
                    ); // Clear previous errors

                    try {
                      // 1. Get the user's household_id
                      // (Assuming they only have one primary household for now)
                      final householdRes = await supabase
                          .from('household_member_tab')
                          .select('household_id')
                          .eq('user_id', supabase.auth.currentUser!.id)
                          .limit(1);

                      if (householdRes.isEmpty) {
                        setDialogState(
                          () => errorMessage =
                              "You do not belong to a household.",
                        );
                        return;
                      }

                      final householdId = householdRes.first['household_id'];

                      // 2. Check if the room already exists in THIS household (case-insensitive)
                      final existingRooms = await supabase
                          .from('room_tab')
                          .select('room_id')
                          .eq('household_id', householdId)
                          .ilike(
                            'room_name',
                            roomName,
                          ); // ilike ignores upper/lowercase differences

                      if (existingRooms.isNotEmpty) {
                        setDialogState(
                          () => errorMessage =
                              "A room with this name already exists.",
                        );
                        return;
                      }

                      // 3. Insert the new room
                      await supabase.from('room_tab').insert({
                        'room_name': roomName,
                        'household_id': householdId,
                      });

                      // 4. Close the dialog and refresh the grid
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _roomsFuture =
                              fetchRooms(); // Triggers the FutureBuilder to rebuild
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added $roomName')),
                        );
                      }
                    } catch (error) {
                      setDialogState(
                        () => errorMessage =
                            "Failed to add room. Please try again.",
                      );
                      debugPrint(error.toString());
                    }
                  },
                  child: const Text("Save"),
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
      appBar: AppBar(title: const Text("Select the room to modify")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _roomsFuture, // Use the state variable here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading rooms: ${snapshot.error}"),
            );
          }

          final rooms = snapshot.data;
          if (rooms == null || rooms.isEmpty) {
            return const Center(
              child: Text(
                "No rooms found. Add a room to your household first.",
              ),
            );
          }
					
					return RoomGrid(
						rooms: rooms,
						onRoomSelected: (room) {
							Navigator.push(
								context,
								MaterialPageRoute(
									builder: (context) => GenericShelvesPage(
										roomId: room['room_id'].toString(),
										roomName: room['room_name'].toString(),
										householdId: room['household_id'].toString(),
										pageTitle: "Manage Shelves in ${room['room_name']}",
										onShelfSelected: (shelf, context) {
											_showEditShelfDialog(context, shelf);
										}
									), //RemoveBooksShelvesPage
								), //MaterialPageRoute
							);
						},
					); //RoomGrid
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomDialog(context), // Trigger the new dialog
        tooltip: 'Add Room',
        child: const Icon(Icons.add),
      ),
    );
  }
}
