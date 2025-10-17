import 'package:flutter/material.dart';

class RequestBookDetailsPage extends StatefulWidget {
  final String? requestId;
  final String? status;
  
  const RequestBookDetailsPage({
    super.key,
    this.requestId,
    this.status,
  });

  @override
  State<RequestBookDetailsPage> createState() => _RequestBookDetailsPageState();
}

class _RequestBookDetailsPageState extends State<RequestBookDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _authorController = TextEditingController();
  final _pdfUrlController = TextEditingController();
  
  bool _imageUploaded = false;
  String _userRole = "Student";

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _authorController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  void _pickImage() {
    setState(() {
      _imageUploaded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image upload simulated - integrate with file picker'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _pickPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF upload simulated - integrate with file picker'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book request submitted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requestId != null) {
      return _buildStatusView();
    }
    
    return _buildRequestForm();
  }

  Widget _buildRequestForm() {
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
          "Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2D35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _imageUploaded 
                                  ? Icons.check_circle 
                                  : Icons.upload,
                              color: _imageUploaded 
                                  ? Colors.green 
                                  : const Color(0xFF0A84FF),
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _imageUploaded ? "Uploaded" : "Upload img",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _titleController.text.isEmpty 
                          ? "Introduction to\nQuantum Computing" 
                          : _titleController.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Role",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _userRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Book ISBN: ",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _isbnController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "123512ASED",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ISBN';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Author: ",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _authorController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Robert Johnson",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter author name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "PDF: Paste the URL or Upload .pdf",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickPdf,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1B1E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.upload,
                          color: Color(0xFF0A84FF),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Request to add",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    final status = widget.status ?? 'Pending';
    
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
          "Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2D35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Upload img",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Introduction to\nQuantum Computing",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Role",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Student",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Book ISBN: 123512ASED",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Author: Robert Johnson",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "PDF: Paste the URL or Upload .pdf",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1B1E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.upload,
                      color: Color(0xFF0A84FF),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            _buildStatusProgress(status),
            
            const SizedBox(height: 16),
            
            Text(
              "Status: $status",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgress(String currentStatus) {
    final statuses = ['Requested', 'Pending', 'Added'];
    final currentIndex = statuses.indexOf(currentStatus);
    
    return Row(
      children: [
        for (int i = 0; i < statuses.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: i <= currentIndex 
                    ? (i == 0 ? const Color(0xFF4CAF50) : 
                       i == 1 ? const Color(0xFFFFA726) : 
                       const Color(0xFFFF9800))
                    : const Color(0xFF2C2D35),
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(8) : Radius.zero,
                  right: i == statuses.length - 1 ? const Radius.circular(8) : Radius.zero,
                ),
              ),
              child: Text(
                statuses[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: i <= currentIndex ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: i == currentIndex ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (i < statuses.length - 1)
            Container(
              width: 2,
              height: 40,
              color: const Color(0xFF1A1B1E),
            ),
        ],
      ],
    );
  }
}
