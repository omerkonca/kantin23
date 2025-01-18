import 'package:flutter/material.dart';

class TransactionHistory extends StatelessWidget {
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> transactions = [
      {"product": "Kola", "amount": "10", "date": "2025-01-18"},
      {"product": "Sandviç", "amount": "15", "date": "2025-01-17"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Harcama Geçmişi"),
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return ListTile(
            title: Text(transaction["product"]!),
            subtitle: Text(transaction["date"]!),
            trailing: Text("-₺${transaction["amount"]}"),
          );
        },
      ),
    );
  }
}
