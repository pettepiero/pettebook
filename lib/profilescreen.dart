import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("This is the Profile screen.")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        },
        tooltip: "Sign Out", 
        child: const Icon(Icons.logout),
        ),
    );
    
  }
}


Future<void> joinHouseholdWithPasskey(BuildContext context) async {
  final TextEditingController passkeyController = TextEditingController();
  final supabase = Supabase.instance.client;
  String? errorMessage;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Join Shared Library"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter the 8-character passkey for the household you want to join."),
                const SizedBox(height: 12),
                TextField(
                  controller: passkeyController,
                  decoration: const InputDecoration(labelText: "Passkey"),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () async {
                  final passkey = passkeyController.text.trim();
                  if (passkey.isEmpty) return;

                  try {
                    // 1. Find the household with this passkey
                    final response = await supabase
                        .from('household_tab')
                        .select('household_id, household_name')
                        .eq('passkey', passkey)
                        .maybeSingle(); // Returns null if not found

                    if (response == null) {
                      setDialogState(() => errorMessage = "Invalid passkey.");
                      return;
                    }

                    // 2. Insert the user into the household members table
                    await supabase.from('household_member_tab').insert({
                      'household_id': response['household_id'],
                      'user_id': supabase.auth.currentUser!.id,
                      'role': 'member', // Default to normal member
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully joined ${response['household_name']}!')),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => errorMessage = "You are already a member, or an error occurred.");
                  }
                },
                child: const Text("Join"),
              ),
            ],
          );
        }
      );
    },
  );
}