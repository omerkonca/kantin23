import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'product_management.dart';
import 'sales_report_screen.dart';
import 'student_form.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authService.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              } catch (e) {
                NotificationService.showError('Çıkış yapılırken hata oluştu');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('Admin'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Yönetim',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  'Ürün Yönetimi',
                  Icons.shopping_bag,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductManagement(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Öğrenci Ekle',
                  Icons.person_add,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentForm(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Satış Raporu',
                  Icons.bar_chart,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalesReportScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
