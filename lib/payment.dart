import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'auth_service.dart';
import 'payment_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Future<Fine?> _finesFuture;
  late Future<List<PaymentRecord>> _historyFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _finesFuture = PaymentService.fetchOutstandingFines();
    _historyFuture = PaymentService.fetchPaymentHistory();
  }

  void _refreshData() {
    setState(() {
      _finesFuture = PaymentService.fetchOutstandingFines();
      _historyFuture = PaymentService.fetchPaymentHistory();
    });
  }

  Future<void> _processPayment(Fine fine) async {
    if (fine.fines.isEmpty && fine.pendingFines.isEmpty) return;

    // Auto-select bKash (only payment method)
    const paymentMethod = 'bkash';
    
    if (paymentMethod == 'bkash') {
      // Show bKash payment info dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2C2D35),
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.pink[300]),
                const SizedBox(width: 8),
                const Text(
                  'bKash Payment',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please send payment to:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bKash Number:',
                        style: TextStyle(
                          color: Colors.pink[900],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '01XXXXXXXXX',
                        style: TextStyle(
                          color: Colors.pink[900],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: BDT ${fine.totalOutstanding.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.pink[900],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'After sending payment, visit the library with your transaction ID to verify.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                ),
                child: const Text(
                  'I have sent payment',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isProcessing = true;
    });

    final fineIds = fine.fines.map((f) => f.fineId).toList();
    final transactionIds = fine.pendingFines
        .map((f) => f.transactionId)
        .toList();
    final result = await PaymentService.processPayment(
      fineIds,
      transactionIds: transactionIds,
      paymentMethod: paymentMethod,
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? Colors.green : Colors.redAccent,
      ),
    );

    if (result.ok) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Fine?>(
              future: _finesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    color: Colors.red[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  );
                }

                final fine = snapshot.data;
                if (fine == null || fine.totalOutstanding == 0) {
                  return Card(
                    color: Colors.green[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Outstanding Fines",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "No Outstanding Fines",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You're all caught up!",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  color: Colors.red[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Outstanding Fines",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "BDT ${fine.totalOutstanding.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Total Fines: ${fine.finesCount + fine.pendingFinesCount}",
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7) ??
                                Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (fine.fines.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: fine.fines
                                  .map(
                                    (f) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              f.description ?? 'Fine',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'BDT ${f.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (fine.pendingFines.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pending (Overdue Books)',
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...fine.pendingFines
                                    .map(
                                      (f) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                f.description ?? 'Overdue fine',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'BDT ${f.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _processPayment(fine),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Pay Now",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Payment History",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<PaymentRecord>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data ?? [];
                if (payments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No payment history',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  );
                }

                return Column(
                  children: payments
                      .map(
                        (payment) => PaymentHistoryCard(
                          date: payment.paymentDate ?? 'Unknown',
                          amount: 'BDT ${payment.amount.toStringAsFixed(2)}',
                          description: payment.description ?? 'Payment',
                          cardColor: cardColor,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleBottomNav(currentIndex: 2),
    );
  }
}

class PaymentHistoryCard extends StatelessWidget {
  final String date, amount, description;
  final Color cardColor;

  const PaymentHistoryCard({
    super.key,
    required this.date,
    required this.amount,
    required this.description,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_circle, color: Colors.white),
        ),
        title: Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          date,
          style: TextStyle(
            color:
                Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.white70,
            fontSize: 13,
          ),
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
