import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'package:provider/provider.dart';

class ProductForm extends StatefulWidget {
  final Product? product;

  const ProductForm({super.key, this.product});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _qrCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _barcodeController.text = widget.product!.barcode ?? '';
      _qrCodeController.text = widget.product!.qrCode ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  String _generateQrCode() {
    // Basit bir QR kod oluşturma mantığı
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'PRD${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final apiService = await ApiService.create(authToken: authService.token);

        final product = Product(
          id: widget.product?.id ?? '',
          name: _nameController.text,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
          qrCode: _qrCodeController.text.isEmpty ? _generateQrCode() : _qrCodeController.text,
          imageUrl: widget.product?.imageUrl,
        );

        if (widget.product == null) {
          await apiService.createProduct(product);
          NotificationService.showSuccess('Ürün başarıyla oluşturuldu');
        } else {
          await apiService.updateProduct(product);
          NotificationService.showSuccess('Ürün başarıyla güncellendi');
        }

        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        NotificationService.showError('Hata: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewProduct = widget.product == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewProduct ? 'Yeni Ürün' : 'Ürün Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ürün adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '₺',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiyat gerekli';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir fiyat girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok miktarı gerekli';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barkod (İsteğe bağlı)',
                  prefixIcon: Icon(Icons.qr_code),
                  helperText: 'Barkod varsa giriniz',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qrCodeController,
                decoration: const InputDecoration(
                  labelText: 'QR Kod',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isNewProduct ? 'Ürün Oluştur' : 'Değişiklikleri Kaydet',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
