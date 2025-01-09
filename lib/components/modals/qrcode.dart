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

class QrcodeModalState extends ConsumerState<QrcodeModal> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late String _qrData;
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

    _updateQrCode();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _updateQrCode();
      });
    });
  }

  void _updateQrCode() {
    final basicFit = ref.read(authNotifierProvider);
    _qrData = BasicFit.generateQrcodeData(basicFit.member?.cardnumber ?? '', basicFit.member?.deviceId ?? '');
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

    return FractionallySizedBox(
      heightFactor: 0.8,
      alignment: Alignment.center,
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
          const SizedBox(height: 1.0),
          Text(
            "Utilise ce QR code pour accéder au club",
            style: TextStyle(
              color: Colors.white,
              fontSize: 3.5.w,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 25.w, right: 25.w, top: 2.h, bottom: 1.h),
            child: Column(
              children: [
                QrImageView(
                  data: _qrData,
                  version: 2,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: 1.h),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _animation.value,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    );
                  },
                ),
              ],
            ),
          ),
          Text(
            "Carte ${basicFit.member?.cardnumber}",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 3.5.w,
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}