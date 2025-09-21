import 'package:basicshare/components/layout/days.dart';
import 'package:basicshare/components/layout/influence.dart';
import 'package:basicshare/components/layout/health_pie_chart.dart';
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

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: FloatingActionButton(
          backgroundColor:
              basicFit.member != null ? Colors.deepOrange : Colors.grey,
          onPressed: basicFit.member != null
              ? () async {
                  await ScreenBrightness.instance
                      .setApplicationScreenBrightness(1.0);

                  if (!mounted) return;

                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (context) {
                      return const QrcodeModal();
                    },
                  );

                  await ScreenBrightness.instance
                      .resetApplicationScreenBrightness();
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          "Impossible d'afficher le QR code. Les informations du membre ne sont pas disponibles."),
                      backgroundColor: Colors.orange,
                      action: SnackBarAction(
                        label: "Réessayer",
                        textColor: Colors.white,
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier);
                        },
                      ),
                    ),
                  );
                },
          child: const Icon(Icons.qr_code),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 18.0,
            right: 18.0,
            top: 18.0,
            bottom: 8.h,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (basicFit.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child:
                          CircularProgressIndicator(color: Colors.deepOrange),
                    ),
                  ),
                if (basicFit.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            basicFit.errorMessage!,
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier);
                          },
                          child: const Text("Réessayer",
                              style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                  ),
                Text(
                  basicFit.member != null
                      ? "Salut, ${basicFit.member!.firstname} 👋"
                      : "Salut 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5.w,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                WeekSelector(
                    selectedDates: basicFit.visits
                            ?.map((e) => DateTime.parse(e.swipeDateTime))
                            .toList() ??
                        []),
                SizedBox(height: 1.h),
                LineChartSample2(
                  lineData: basicFit.todayInflux?.entries
                          .map((e) => FlSpot(double.parse(e.key.toString()),
                              double.parse(e.value.toString()) / 15))
                          .toList() ??
                      [],
                ),
                if (basicFit.healthMeasurements != null &&
                    basicFit.healthMeasurements!.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  HealthPieChart(
                      healthData: basicFit.healthMeasurements!.first),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
