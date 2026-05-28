import 'package:flutter/material.dart';

class EditCatalogScreen extends StatefulWidget {
  const EditCatalogScreen({super.key});

  @override
  State<EditCatalogScreen> createState() => _EditCatalogScreenState();
}


class _EditCatalogScreenState extends State<EditCatalogScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("This is the Edit Catalog screen.")),
    );
    
  }
}