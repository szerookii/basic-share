import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sizer/sizer.dart';

class FriendQrcodeModal extends StatefulWidget {
  final String friendName;
  final String cardNumber;

  const FriendQrcodeModal({
    super.key,
    required this.friendName,
    required this.cardNumber,
  });

  @override
  FriendQrcodeModalState createState() => FriendQrcodeModalState();
}

class FriendQrcodeModalState extends State<FriendQrcodeModal> {
  @override
  void initState() {
    super.initState();
    _setBrightness();
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  void _setBrightness() async {
    await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
  }

  void _resetBrightness() async {
    await ScreenBrightness.instance.resetApplicationScreenBrightness();
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
              "QR Code de ${widget.friendName}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.w,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              "Carte numéro ${widget.cardNumber}",
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
                  data: widget.cardNumber,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
          ],
        ),
      ),
    );
  }
}
