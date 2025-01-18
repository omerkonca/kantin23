import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/sales.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late ApiService _apiService;
  Sales? _dailySales;
  Sales? _weeklySales;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initApiService();
  }

  Future<void> _initApiService() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = await ApiService.create(authToken: authService.token);
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);

    try {
      final daily = await _apiService.getDailySales(_selectedDate);
      final weekly = await _apiService.getWeeklySales();

      setState(() {
        _dailySales = daily;
        _weeklySales = weekly;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSalesData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Satış Raporu'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDate,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSalesData,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Günlük'),
              Tab(text: 'Haftalık'),
              Tab(text: 'En Çok Satanlar'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildDailyReport(),
                  _buildWeeklyReport(),
                  _buildTopProducts(),
                ],
              ),
      ),
    );
  }

  Widget _buildDailyReport() {
    if (_dailySales == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd MMMM yyyy').format(_selectedDate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Toplam Satış',
                    '₺${_dailySales!.totalAmount.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'İşlem Sayısı',
                    _dailySales!.totalTransactions.toString(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ürün Detayları',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dailySales!.productSales.length,
            itemBuilder: (context, index) {
              final product = _dailySales!.productSales[index];
              return Card(
                child: ListTile(
                  title: Text(product.productName),
                  subtitle: Text('${product.quantity} adet'),
                  trailing: Text(
                    '₺${product.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReport() {
    if (_weeklySales == null || _weeklySales!.dailySales == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('dd MMM').format(_weeklySales!.startDate!)} - '
            '${DateFormat('dd MMM yyyy').format(_weeklySales!.endDate!)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Toplam Satış',
                    '₺${_weeklySales!.totalAmount.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'İşlem Sayısı',
                    _weeklySales!.totalTransactions.toString(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Günlük Detaylar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _weeklySales!.dailySales!.length,
            itemBuilder: (context, index) {
              final daily = _weeklySales!.dailySales![index];
              return Card(
                child: ListTile(
                  title: Text(DateFormat('EEEE').format(daily.date)),
                  subtitle: Text('${daily.totalTransactions} işlem'),
                  trailing: Text(
                    '₺${daily.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    if (_weeklySales?.productSales == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _weeklySales!.productSales.length,
      itemBuilder: (context, index) {
        final product = _weeklySales!.productSales[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(product.productName),
            subtitle: Text('${product.quantity} adet'),
            trailing: Text(
              '₺${product.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
