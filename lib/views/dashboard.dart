import 'package:basicshare/components/modals/qrcode.dart';
import 'package:basicshare/state/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sizer/sizer.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basicFit = ref.watch(authNotifierProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () async {
          await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);

          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) {
              return const QrcodeModal();
            },
          );

          await ScreenBrightness.instance.resetApplicationScreenBrightness();
        },
        child: const Icon(Icons.qr_code),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Salut, ${basicFit.member?.firstname} 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String generateOptimizedData(String input) {
    String numericPart = "";
    String alphanumericPart = "";

    // Iterate through the input string and separate the numbers and letters
    for (int i = 0; i < input.length; i++) {
      if (isNumeric(input[i])) {
        numericPart += input[i];
      } else {
        alphanumericPart += input[i];
      }
    }

    // Combine both numeric and alphanumeric parts
    return numericPart + ":" + alphanumericPart;
  }

  bool isNumeric(String s) {
    return int.tryParse(s) != null;
  }
}
