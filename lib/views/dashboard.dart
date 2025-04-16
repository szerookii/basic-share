import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:basicshare/components/layout/days.dart';
import 'package:basicshare/components/layout/influence.dart';
import 'package:basicshare/components/modals/qrcode.dart';
import 'package:basicshare/state/auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sizer/sizer.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final basicFit = ref.watch(authNotifierProvider);

    Aptabase.instance.trackEvent("dashboard_opened", {
      "name": basicFit.member?.firstname,
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () async {
          await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);

          if (!mounted) return;

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
        child: SingleChildScrollView(
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
                SizedBox(height: 1.h),
                WeekSelector(selectedDates: basicFit.visits?.map((e) => DateTime.parse(e.swipeDateTime)).toList() ?? []),
                SizedBox(height: 1.h),
                LineChartSample2(
                  lineData: basicFit.todayInflux?.entries.map((e) => FlSpot(double.parse(e.key.toString()), double.parse(e.value.toString()) / 15)).toList() ?? [],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
