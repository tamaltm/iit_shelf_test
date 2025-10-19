import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'auth_service.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);

    return Scaffold(
      backgroundColor: Colors.black,
  appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.red[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Outstanding Fines",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "BDT 150.00",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Overdue Books: 2",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: cardColor,
                              title: const Text("Payment Successful", style: TextStyle(color: Colors.white)),
                              content: const Text(
                                "Your fine of BDT 150.00 has been paid successfully.",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Pay Now", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Payment History",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            PaymentHistoryCard(
              date: "2024-05-15",
              amount: "BDT 50.00",
              description: "Late return fine",
              cardColor: cardColor,
            ),
            PaymentHistoryCard(
              date: "2024-04-20",
              amount: "BDT 100.00",
              description: "Damaged book fine",
              cardColor: cardColor,
            ),
            PaymentHistoryCard(
              date: "2024-03-10",
              amount: "BDT 30.00",
              description: "Late return fine",
              cardColor: cardColor,
            ),
          ],
        ),
      ),
  bottomNavigationBar: const RoleBottomNav(currentIndex: 2), // Fixed index from 3 to 2 for Payments
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
        title: Text(description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(date, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        trailing: Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
