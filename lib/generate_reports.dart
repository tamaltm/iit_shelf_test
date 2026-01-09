import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'report_service.dart';

class GenerateReportsPage extends StatefulWidget {
  final String? userRole; // 'librarian' or 'director'
  
  const GenerateReportsPage({super.key, this.userRole});

  @override
  State<GenerateReportsPage> createState() => _GenerateReportsPageState();
}

class _GenerateReportsPageState extends State<GenerateReportsPage> {
  String startDate = "2023-01-01";
  String endDate = "2023-06-30";
  String selectedReportType = "";
  bool _isGenerating = false;
  List<RecentReport> _recentReports = [];
  dynamic _generatedData;
  
  final Map<String, String> reportTypes = {
    'most_borrowed': 'Most Borrowed Books',
    'most_requested': 'Most Requested Books',
    'semester_wise': 'Semester Wise Borrowing',
    'session_wise': 'Session Wise Borrowing',
  };

  @override
  void initState() {
    super.initState();
    // Ensure dropdown value matches the available options
    selectedReportType = reportTypes.keys.first;
    _loadRecentReports();
    // Set default date range to last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    startDate = _formatDate(thirtyDaysAgo);
    endDate = _formatDate(now);
  }

  Future<void> _loadRecentReports() async {
    final reports = await ReportService.getRecentReports();
    setState(() {
      _recentReports = reports;
    });
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _generatedData = null;
    });

    final result = await ReportService.generateReport(
      reportType: selectedReportType,
      startDate: startDate,
      endDate: endDate,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      if (result.success) {
        setState(() {
          _generatedData = result.data;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportReport(String format) async {
    if (_generatedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a report first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    final result = await ReportService.downloadReport(
      reportType: selectedReportType,
      startDate: startDate,
      endDate: endDate,
      format: format,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to:\n${result.filePath}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                  
                  // Report Type Dropdown
                  const Text(
                    "Report Type",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    selectedReportType,
                    reportTypes.keys.toList(),
                    (value) {
                      setState(() => selectedReportType = value!);
                    },
                    displayMapper: (value) => reportTypes[value] ?? value,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Generate Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.assessment, color: Colors.white),
                label: Text(
                  _isGenerating ? "Generating..." : "Generate Report",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  disabledBackgroundColor: Colors.grey,
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
                    onPressed: _isGenerating ? null : () => _exportReport('pdf'),
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
                    onPressed: _isGenerating ? null : () => _exportReport('csv'),
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
            
            // Display generated data if available
            if (_generatedData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Report Results",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _generatedData = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildReportDataView(_generatedData),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
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
            
            if (_recentReports.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recent reports',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              ..._recentReports.take(3).map((report) => Column(
                    children: [
                      _buildRecentReportItem(
                        report.title,
                        () async {
                          setState(() {
                            selectedReportType = report.reportType;
                          });
                          await _generateReport();
                        },
                      ),
                      const Divider(color: Colors.white24, height: 1),
                    ],
                  )),
            
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
          ],
        ),
      ),
  bottomNavigationBar: RoleBottomNav(currentIndex: 2, role: widget.userRole),
    );
  }

  Widget _buildReportDataView(dynamic data) {
    if (data == null) {
      return const Text(
        'No data available',
        style: TextStyle(color: Colors.white54),
      );
    }

    // Handle different report types
    if (data is Map) {
      // Summary or fines report
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatKey(entry.key),
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (data is List) {
      // List of items
      if (data.isEmpty) {
        return const Text(
          'No records found for the selected period',
          style: TextStyle(color: Colors.white54),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Records: ${data.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...data.take(5).map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (item as Map<String, dynamic>).entries.take(4).map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${_formatKey(e.key)}: ${e.value}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          if (data.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${data.length - 5} more records',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      );
    }

    return Text(
      data.toString(),
      style: const TextStyle(color: Colors.white70),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
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

  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged, {
    String Function(String)? displayMapper,
  }) {
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
              child: Text(displayMapper != null ? displayMapper(item) : item),
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
}
