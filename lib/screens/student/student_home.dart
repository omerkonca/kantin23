import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/transaction.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'qr_scanner_screen.dart';
import 'package:intl/intl.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMoreTransactions = true;
  int _currentPage = 1;
  static const int _transactionsPerPage = 20;
  bool _isOffline = false;
  late TabController _tabController;
  final Map<String, int> _cart = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMoreTransactions) {
      _loadTransactions();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTransactions(refresh: true),
      _loadProducts(),
    ]);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = await ApiService.create(authToken: authService.token);
      final products = await apiService.getProducts();

      setState(() {
        _products = products;
        _isOffline = false;
      });
    } catch (e) {
      setState(() => _isOffline = true);
      NotificationService.showError('Ürünler yüklenemedi: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _transactions.clear();
        _hasMoreTransactions = true;
      }
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = await ApiService.create(authToken: authService.token);
      
      final newTransactions = await apiService.getStudentTransactions(
        authService.currentUser!.id,
        page: _currentPage,
        limit: _transactionsPerPage,
      );

      setState(() {
        if (refresh) {
          _transactions = newTransactions;
        } else {
          _transactions.addAll(newTransactions);
        }
        _hasMoreTransactions = newTransactions.length == _transactionsPerPage;
        _currentPage++;
        _isOffline = false;
      });
    } catch (e) {
      setState(() => _isOffline = true);
      NotificationService.showError('İşlemler yüklenemedi: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(Product product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
    NotificationService.showSuccess('${product.name} sepete eklendi');
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        if (_cart[product.id]! > 1) {
          _cart[product.id] = _cart[product.id]! - 1;
        } else {
          _cart.remove(product.id);
        }
      }
    });
  }

  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = _products.firstWhere((p) => p.id == entry.key);
      total += product.price * entry.value;
    }
    return total;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      NotificationService.showError('Sepetiniz boş');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser!.balance < _cartTotal) {
      NotificationService.showError('Yetersiz bakiye');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = await ApiService.create(authToken: authService.token);
      
      for (final entry in _cart.entries) {
        final productId = entry.key;
        final quantity = entry.value;
        
        await apiService.processPayment(
          studentId: authService.currentUser!.id,
          productId: productId,
          quantity: quantity,
        );
      }

      setState(() => _cart.clear());
      await authService.updateUserProfile();
      await _loadTransactions(refresh: true);
      
      NotificationService.showSuccess('Ödeme başarılı');
    } catch (e) {
      NotificationService.showError('Ödeme başarısız: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Paneli'),
        actions: [
          if (_isOffline)
            const Icon(Icons.cloud_off, color: Colors.orange),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authService.logout();
                if (!mounted) return;
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Ürünler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profil Sekmesi
          RefreshIndicator(
            onRefresh: () => _loadTransactions(refresh: true),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                            Text(user.studentId),
                            const SizedBox(height: 8),
                            Text(
                              '₺${user.balance.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: QrImageView(
                        data: user.id,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Son İşlemler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _transactions.isEmpty
                        ? const Center(
                            child: Text('İşlem bulunamadı'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length + (_hasMoreTransactions ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _transactions.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final transaction = _transactions[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: transaction.amount < 0
                                        ? Colors.red
                                        : Colors.green,
                                    child: Icon(
                                      transaction.amount < 0
                                          ? Icons.remove
                                          : Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(transaction.description),
                                  subtitle: Text(
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(transaction.date),
                                  ),
                                  trailing: Text(
                                    '₺${transaction.amount.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: transaction.amount < 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
          // Ürünler Sekmesi
          RefreshIndicator(
            onRefresh: _loadProducts,
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final quantity = _cart[product.id] ?? 0;

                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('₺${product.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (quantity > 0) ...[
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _removeFromCart(product),
                              ),
                              Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: product.stock > quantity
                                  ? () => _addToCart(product)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_cart.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Toplam',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₺${_cartTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _checkout,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Ödeme Yap',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QR Kod Tara'),
            )
          : null,
    );
  }
}
