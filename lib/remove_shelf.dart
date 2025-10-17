import 'package:flutter/material.dart';

class RemoveShelfPage extends StatefulWidget {
  const RemoveShelfPage({super.key});

  @override
  State<RemoveShelfPage> createState() => _RemoveShelfPageState();
}

class _RemoveShelfPageState extends State<RemoveShelfPage> {
  final _shelfNoController = TextEditingController();
  final _compartmentNoController = TextEditingController();
  final _subCompartmentNoController = TextEditingController();

  @override
  void dispose() {
    _shelfNoController.dispose();
    _compartmentNoController.dispose();
    _subCompartmentNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2D35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "IITShelf",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage("assets/profile.jpg"),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2D35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Remove Shelf",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              _buildTextField("Shelf No:", _shelfNoController),
              const SizedBox(height: 20),
              _buildTextField("Compartment No:", _compartmentNoController),
              const SizedBox(height: 20),
              _buildTextField("Sub-Compartment No:", _subCompartmentNoController),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: () {
                  // Handle remove shelf logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Shelf removed successfully!")),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Remove",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1B1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
