import 'dart:async';

import 'package:basicshare/basicfit/basicfit.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sizer/sizer.dart';

class ManualAccessQrcodeModal extends StatefulWidget {
  final String cardNumber;
  final String deviceId;

  const ManualAccessQrcodeModal({
    super.key,
    required this.cardNumber,
    required this.deviceId,
  });

  @override
  ManualAccessQrcodeModalState createState() => ManualAccessQrcodeModalState();
}

class ManualAccessQrcodeModalState extends State<ManualAccessQrcodeModal>
    with SingleTickerProviderStateMixin {
  late final Timer _timer;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final String _guid;
  String _qrData = "";

  @override
  void initState() {
    super.initState();

    _guid = BasicFit.generateOfflineGUID();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: false);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _updateQrCode();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        _updateQrCode();
      });
    });
  }

  void _updateQrCode() {
    _qrData = BasicFit.generateQrcodeData(
      widget.cardNumber,
      widget.deviceId,
      _guid,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "QR Code manuel",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.w,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              "Utilise ce QR code pour acceder au club",
              style: TextStyle(
                color: Colors.white,
                fontSize: 3.5.w,
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
                  version: QrVersions.auto,
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
              "Carte ${widget.cardNumber}",
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
