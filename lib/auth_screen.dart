import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget{
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
  
      if (_isSignUp) {
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up successful! Please confirm you email and log in.')),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await supabase.auth.signInWithPassword(
            email: email,
            password: password,
        );

        print("Logged in successfully!");
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occured."), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? "Create Account" : "Welcome Back")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isSignUp) ...[
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _authenticate, 
              child: _isLoading
                ? const CircularProgressIndicator()
                : Text(_isSignUp ? "Sign Up" : "Log In"),
            ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp), 
              child: Text(_isSignUp
                ? "Already have an account? Log In"
                : "Need an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}