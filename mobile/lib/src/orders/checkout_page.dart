import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../api/authed_api_client.dart';

class CheckoutPage extends StatefulWidget {
  final String orderId;
  final AuthedApiClient api;
  
  const CheckoutPage({super.key, required this.orderId, required this.api});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = true;
  String? _qrString;
  String? _error;
  double _total = 0.0;
  bool _isDisposed = false;
  String _status = 'PENDING';

  int _timeLeft = 900; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchQR();
    _startPaymentCheck();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel(); 
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && mounted) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchQR() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _timeLeft = 900; 
    });

    try {
      final response = await widget.api.getBakongQR(widget.orderId);
      if (_isDisposed || !mounted) return;

      setState(() {
        _qrString = response['qrString']?.toString();
        _total = (response['totalUsd'] as num? ?? 0.0).toDouble();
        _loading = false;
        
        if (_qrString == null) {
          _error = "Server Error: QR data was not generated correctly.";
        } else {
          _startTimer();
        }
      });
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _error = "Payment Error: ${e.toString().replaceAll('Exception: ', '')}";
        _loading = false;
      });
    }
  }

  void _startPaymentCheck() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (_isDisposed || !mounted || _status == 'PAID' || _timeLeft <= 0) return false;
      
      try {
        final res = await widget.api.verifyPayment(widget.orderId);
        if (res['status'] == 'PAID' && mounted) {
          setState(() => _status = 'PAID');
          _timer?.cancel(); 
          _showSuccessDialog();
          return false; 
        }
      } catch (e) {
        debugPrint("Still waiting for payment...");
      }
      return true; 
    });
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 90),
            const SizedBox(height: 16),
            const Text('Payment Success!', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your order has been confirmed and is being processed.', 
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor, height: 1.4)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).popUntil((route) => route.isFirst); 
                },
                child: const Text('Return to Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _formattedTime {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('KHQR Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text("Generating Secure KHQR...", 
            style: TextStyle(color: theme.hintColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 80),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _fetchQR, 
              icon: const Icon(Icons.refresh),
              label: const Text("Retry Payment"),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text('Bakong KHQR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Scan with any Cambodian Bank App', style: TextStyle(color: theme.hintColor, fontSize: 14)),
        const SizedBox(height: 24),
        
        Text('\$${_total.toStringAsFixed(2)}', 
          style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
        
        const SizedBox(height: 24),
        
        // The QR Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white, // KHQR backgrounds are strictly white for scanners
            borderRadius: BorderRadius.circular(28),
            boxShadow: isDark ? null : [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))
            ],
            border: isDark ? Border.all(color: Colors.white24) : null,
          ),
          child: Column(
            children: [
              _timeLeft > 0 
                ? (_qrString != null 
                    ? QrImageView(
                        data: _qrString!, 
                        version: QrVersions.auto, 
                        size: 240.0,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      )
                    : const SizedBox(width: 240, height: 240, child: Center(child: Text("Data Error"))))
                : Container(
                    width: 240, height: 240,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_off_outlined, size: 50, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("QR Expired", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
              
              const SizedBox(height: 24),
              const Text("SOKING OEUN", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.black)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text("Verified Bakong Account", 
                    style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionIcon(context, Icons.download_rounded, "Save QR"),
            const SizedBox(width: 48),
            _buildActionIcon(context, Icons.share_rounded, "Share"),
          ],
        ),

        const SizedBox(height: 40),
        
        _timeLeft > 0 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.primary)),
                  const SizedBox(width: 12),
                  Text('Waiting for payment... ', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(_formattedTime, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            )
          : FilledButton.icon(
              onPressed: _fetchQR, 
              icon: const Icon(Icons.refresh), 
              label: const Text("Generate New QR"),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, 
                minimumSize: const Size(200, 48)
              ),
            ),
        
        const SizedBox(height: 24),
        Text("Order ID: ${widget.orderId.substring(widget.orderId.length - 8).toUpperCase()}", 
          style: TextStyle(color: theme.hintColor, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(icon, color: theme.iconTheme.color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.hintColor)),
      ],
    );
  }
}