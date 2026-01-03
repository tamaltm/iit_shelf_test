import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';

class GenerateReportsPage extends StatefulWidget {
  final String? userRole; // 'librarian' or 'director'
  
  const GenerateReportsPage({super.key, this.userRole});

  @override
  State<GenerateReportsPage> createState() => _GenerateReportsPageState();
}

class _GenerateReportsPageState extends State<GenerateReportsPage> {
  String startDate = "2023-01-01";
  String endDate = "2023-06-30";
  String selectedSemester = "All Semester";
  String selectedSession = "All Sessions";
  final List<Map<String, String>> activityItems = [
    {
      'type': 'Borrow',
      'book': 'Introduction to Quantum Computing',
      'user': 'John Doe',
      'id': '12345',
      'date': '2024-01-15',
      'time': '10:30 AM',
      'status': 'Completed',
    },
    {
      'type': 'Return',
      'book': 'Database Management Systems',
      'user': 'Sarah Johnson',
      'id': '12346',
      'date': '2024-01-14',
      'time': '02:15 PM',
      'status': 'Completed',
    },
    {
      'type': 'Fine Payment',
      'book': 'Introduction to Data Science',
      'user': 'Alex Smith',
      'id': '23457',
      'date': '2024-01-14',
      'time': '11:45 AM',
      'status': 'Paid',
      'amount': 'BDT 50.00',
    },
    {
      'type': 'Reservation',
      'book': 'Artificial Intelligence',
      'user': 'Emily Davis',
      'id': '12348',
      'date': '2024-01-13',
      'time': '09:20 AM',
      'status': 'Active',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
  appBar: CustomAppBar(userRole: widget.userRole ?? AuthService.getCurrentUserRole()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Generate Reports",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            
            // Filters Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filters",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Range
                  const Text(
                    "Date Range",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(startDate, _openDateRangePicker),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "—",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ),
                      Expanded(
                        child: _buildDatePicker(endDate, _openDateRangePicker),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Semester Dropdown
                  _buildDropdown(
                    selectedSemester,
                    ["All Semester", "Spring 2023", "Fall 2023", "Spring 2024"],
                    (value) {
                      setState(() => selectedSemester = value!);
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Session Dropdown
                  _buildDropdown(
                    selectedSession,
                    ["All Sessions", "Morning", "Afternoon", "Evening"],
                    (value) {
                      setState(() => selectedSession = value!);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Generate Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Generate report logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Generating report...")),
                  );
                },
                icon: const Icon(Icons.assessment, color: Colors.white),
                label: const Text(
                  "Generate Report",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Export Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white70),
                    label: const Text(
                      "Export PDF",
                      style: TextStyle(color: Colors.white70),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.table_chart, color: Colors.white70),
                    label: const Text(
                      "Export CSV",
                      style: TextStyle(color: Colors.white70),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Reports Section
            const Text(
              "Recent Reports",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildRecentReportItem(
              "Most Borrowed Books - October-2024",
              () {},
            ),
            
            const Divider(color: Colors.white24, height: 1),
            
            _buildRecentReportItem(
              "Fines Collected - September",
              () {},
            ),
            
            const SizedBox(height: 12),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "see all",
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Activity timeline
            const Text(
              "Recent Activity",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ...activityItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActivityCard(item),
                )),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "see all",
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
  bottomNavigationBar: RoleBottomNav(currentIndex: 2, role: widget.userRole),
    );
  }

  Widget _buildDatePicker(String date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openDateRangePicker() async {
    final initialStart = DateTime.tryParse(startDate) ?? DateTime.now().subtract(const Duration(days: 30));
    final initialEnd = DateTime.tryParse(endDate) ?? DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd.isBefore(initialStart) ? initialStart : initialEnd),
      builder: (context, child) {
        // Keep dark theme consistent with page styling
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0A84FF),
              surface: Color(0xFF1A1B1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = _formatDate(picked.start);
        endDate = _formatDate(picked.end);
      });
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C2D35),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRecentReportItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            const Text(
              "View",
              style: TextStyle(
                color: Color(0xFF0A84FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, String> item) {
    final status = item['status'] ?? '';
    final statusColor = _statusColor(status);
    final iconData = _activityIcon(item['type']);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2027),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(iconData, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['book'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        item['type'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _infoRow(Icons.person_outline, 'User', item['user']),
              _infoRow(Icons.badge_outlined, 'ID', item['id']),
              _infoRow(Icons.calendar_today, 'Date', item['date']),
              _infoRow(Icons.access_time, 'Time', item['time']),
              if (item['amount'] != null) _infoRow(Icons.attach_money, 'Amount', item['amount']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 6),
        Text(
          "$label: ${value ?? '-'}",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF46C08A);
      case 'paid':
        return const Color(0xFF46C08A);
      case 'active':
        return const Color(0xFF2F8BFF);
      default:
        return const Color(0xFFAAAAAA);
    }
  }

  IconData _activityIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'borrow':
        return Icons.book_outlined;
      case 'return':
        return Icons.assignment_turned_in_outlined;
      case 'fine payment':
        return Icons.receipt_long_outlined;
      case 'reservation':
        return Icons.event_available_outlined;
      default:
        return Icons.info_outline;
    }
  }
  
}
