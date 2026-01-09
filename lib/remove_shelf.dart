import 'package:flutter/material.dart';
import 'shelf_service.dart';

class RemoveShelfPage extends StatefulWidget {
  const RemoveShelfPage({super.key});

  @override
  State<RemoveShelfPage> createState() => _RemoveShelfPageState();
}

class _RemoveShelfPageState extends State<RemoveShelfPage> {
  List<ShelfLocation> _shelves = [];
  Set<int> _selectedIndices = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShelves();
  }

  Future<void> _loadShelves() async {
    try {
      final shelves = await ShelfService.getShelfLocations();
      setState(() {
        _shelves = shelves;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load shelves: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
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
                  if (_shelves.isEmpty)
                    const Text(
                      "No shelves available",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    )
                  else
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1B1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _shelves.length,
                          itemBuilder: (context, index) {
                            final shelf = _shelves[index];
                            final isSelected = _selectedIndices.contains(index);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedIndices.add(index);
                                    } else {
                                      _selectedIndices.remove(index);
                                    }
                                  });
                                },
                                title: Text(
                                  "Shelf ${shelf.shelfId} - Compartment ${shelf.compartmentNo} - SubCompartment ${shelf.subcompartmentNo}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                fillColor: MaterialStateProperty.all(
                                  Colors.green,
                                ),
                                checkColor: Colors.white,
                                tileColor: isSelected
                                    ? Colors.green.withOpacity(0.2)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _selectedIndices.isEmpty
                        ? null
                        : () async {
                            await _handleRemoveShelves();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.red.withOpacity(0.5),
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
    );
  }

  Future<void> _handleRemoveShelves() async {
    try {
      final selectedShelves = [
        for (int index in _selectedIndices) _shelves[index],
      ];

      for (final shelf in selectedShelves) {
        await ShelfService.removeShelfLocation(
          shelf.shelfId,
          shelf.compartmentNo,
          shelf.subcompartmentNo,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${selectedShelves.length} shelf(ves) removed successfully!",
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error removing shelves: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
