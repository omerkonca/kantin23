import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(seconds: 2);
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String qrCode) async {
    // Prevent duplicate scans
    if (_lastScannedCode == qrCode && 
        _lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) < _scanCooldown) {
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    _lastScannedCode = qrCode;
    _lastScanTime = DateTime.now();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = await ApiService.create(authToken: authService.token);
      
      // QR koddan ürünü al
      final product = await apiService.getProductByQrCode(qrCode);
      
      if (!mounted) return;

      // Miktar seçimi için dialog göster
      final quantity = await _showQuantityDialog(product);
      
      if (quantity == null || !mounted) return;

      // Ödemeyi işle
      final transaction = await apiService.processPayment(
        studentId: authService.currentUser!.id,
        productId: product.id,
        quantity: quantity,
      );

      if (!mounted) return;

      // Başarılı ödeme bildirimi göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ödeme başarılı! Toplam: ₺${transaction.amount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // QR tarayıcıyı kapat
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Reset scan cooldown on error
      _lastScannedCode = null;
      _lastScanTime = null;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<int?> _showQuantityDialog(Product product) async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fiyat: ₺${product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                int quantity = 1;
                return Column(
                  children: [
                    const Text('Miktar:'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => quantity++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toplam: ₺${(product.price * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('Satın Al'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Tarayıcı'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
            onScannerStarted: (arguments) {
              setState(() => _isInitialized = true);
            },
          ),
          if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_isInitialized && !_isProcessing)
            _buildScannerOverlay(),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
