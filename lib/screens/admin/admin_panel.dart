import 'package:flutter/material.dart';
import 'product_management.dart';
import 'sales_report_screen.dart';
import 'student_management.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kantin23 - Yönetici Paneli"),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            "Ürün Yönetimi",
            Icons.inventory,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductManagement(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            "Satış Raporları",
            Icons.bar_chart,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesReportScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            "Öğrenci Yönetimi",
            Icons.people,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentManagement(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            "Ayarlar",
            Icons.settings,
            () {
              // TODO: Implement settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
