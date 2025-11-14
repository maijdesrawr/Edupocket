import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rawr/pos_amount_input_screen.dart';
import 'dart:math' as math;

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isScanned = false;
  double _zoomFactor = 0.5;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleQRScanned(String qrData) {
    if (_isScanned) return;
    _isScanned = true;

    final String recipientNumber = qrData;
    const String paymentTitle = "Payment";

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          recipientNumber: recipientNumber,
          paymentTitle: paymentTitle,
        ),
      ),
    )
        .then((_) {
      _isScanned = false;
    });
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Image.asset(
        'assets/icons/logo-red.png',
        height: 60,
      ),
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Scanning...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAC2324))),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFAC2324),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(74.0),
                  topRight: Radius.circular(74.0),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(74.0),
                  topRight: Radius.circular(74.0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Align the QR Code within the frame to scan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withAlpha(128), width: 2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: MobileScanner(
                              controller: controller,
                              onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                if (barcodes.isNotEmpty) {
                                  final String scannedValue =
                                      barcodes.first.rawValue ??
                                          'No value found';
                                  print('QR CODE SCANNED: $scannedValue');
                                  _handleQRScanned(scannedValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildBottomControls(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  final newZoom = _zoomFactor - 0.1;
                  setState(() {
                    _zoomFactor = math.max(0.0, newZoom);
                    controller.setZoomScale(_zoomFactor);
                  });
                },
              ),
              Expanded(
                child: Slider(
                  value: _zoomFactor,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                  onChanged: (value) {
                    setState(() {
                      _zoomFactor = value;
                      controller.setZoomScale(value);
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  final newZoom = _zoomFactor + 0.1;
                  setState(() {
                    _zoomFactor = math.min(1.0, newZoom);
                    controller.setZoomScale(_zoomFactor);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder(
            valueListenable: controller.torchState,
            builder: (context, state, child) {
              final bool isFlashOn = state == TorchState.on;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => controller.toggleTorch(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: isFlashOn
                          ? Colors.amber[700]
                          : const Color(0xFFAC2324),
                      size: 28,
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
}
