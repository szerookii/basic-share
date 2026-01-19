import 'dart:async';
import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/state/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sizer/sizer.dart';

class QrcodeModal extends ConsumerStatefulWidget {
  const QrcodeModal({super.key});

  @override
  QrcodeModalState createState() => QrcodeModalState();
}

class QrcodeModalState extends ConsumerState<QrcodeModal>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  String _qrData = "";
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: false);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    Future.microtask(() {
      _updateQrCode();
      _startTimer();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _updateQrCode();
      });

      _checkEntry();
    });
  }

  void _updateQrCode() {
    final basicFit = ref.read(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final persistentGuid = authNotifier.getOrCreatePersistentGuid();

    _qrData = BasicFit.generateQrcodeData(basicFit.member?.cardnumber ?? '',
        basicFit.member?.deviceId ?? '', persistentGuid);
  }

  void _checkEntry() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final isConfirmed = await authNotifier.checkAndConfirmEntry();

    if (isConfirmed && mounted) {
      Navigator.of(context).pop();

      _showSuccessModal();
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 12.w,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  "Bonne séance ! 💪",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 6.w,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  "Ton accès au club a été confirmé",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 3.5.w,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                  ),
                  child: Text(
                    "Super !",
                    style: TextStyle(
                      fontSize: 4.w,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _hasRecentVisit() {
    final basicFit = ref.read(authNotifierProvider);
    if (basicFit.visits == null || basicFit.visits!.isEmpty) return false;

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    return basicFit.visits!.any((visit) {
      final visitDate = DateTime.parse(visit.swipeDateTime);
      return visitDate.isAfter(oneHourAgo);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basicFit = ref.read(authNotifierProvider);
    final hasRecentVisit = _hasRecentVisit();

    return FractionallySizedBox(
      heightFactor: 0.85,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Ton QR Code",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.w,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              "Utilise ce QR code pour accéder au club",
              style: TextStyle(
                color: Colors.white,
                fontSize: 3.5.w,
              ),
            ),
            SizedBox(height: 1.5.h),
            if (hasRecentVisit)
              Container(
                margin: EdgeInsets.only(top: 1.h, left: 5.w, right: 5.w),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 4.5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        "Visite récente détectée - Scanner à nouveau pourrait déclencher une alerte",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 2.8.w,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                ),
                padding: const EdgeInsets.all(4),
                child: QrImageView(
                  data: _qrData,
                  version: 2,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _animation.value,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.orange),
                  );
                },
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "Carte ${basicFit.member?.cardnumber}",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 3.5.w,
              ),
            ),
            SizedBox(height: 1.5.h),
          ],
        ),
      ),
    );
  }
}
