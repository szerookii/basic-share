import 'package:basicshare/basicfit/types.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class HealthPieChart extends StatefulWidget {
  final HealthMeasurement? healthData;

  const HealthPieChart({super.key, this.healthData});

  @override
  State<HealthPieChart> createState() => _HealthPieChartState();
}

class _HealthPieChartState extends State<HealthPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.healthData == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 2.h, bottom: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "COMPOSITION CORPORELLE",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              "Dernière mesure: ${_formatDate(widget.healthData!.date)}",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 1,
                        centerSpaceRadius: 50,
                        sections: showingSections(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem("Masse grasse",
                          widget.healthData!.fat ?? 0, Colors.deepOrange),
                      SizedBox(height: 1.2.h),
                      _buildLegendItem("Masse musculaire",
                          widget.healthData!.muscle ?? 0, Colors.green),
                      SizedBox(height: 1.2.h),
                      _buildLegendItem("Masse osseuse",
                          widget.healthData!.bone ?? 0, Colors.grey.shade800),
                      if ((widget.healthData!.water ?? 0) > 0) ...[
                        SizedBox(height: 1.2.h),
                        _buildLegendItem("Eau", widget.healthData!.water ?? 0,
                            Colors.blue.shade300),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${value.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections() {
    final muscle = widget.healthData!.muscle ?? 0;
    final fat = widget.healthData!.fat ?? 0;
    final bone = widget.healthData!.bone ?? 0;
    final water = widget.healthData!.water ?? 0;

    final sections = <PieChartSectionData>[];

    sections.add(PieChartSectionData(
      color: Colors.deepOrange,
      value: fat,
      title: '',
      radius: touchedIndex == 0 ? 25.0 : 20.0,
    ));

    sections.add(PieChartSectionData(
      color: Colors.green,
      value: muscle,
      title: '',
      radius: touchedIndex == 1 ? 25.0 : 20.0,
    ));

    sections.add(PieChartSectionData(
      color: Colors.grey.shade800,
      value: bone,
      title: '',
      radius: touchedIndex == 2 ? 25.0 : 20.0,
    ));

    if (water > 0) {
      sections.add(PieChartSectionData(
        color: Colors.blue.shade300,
        value: water,
        title: '',
        radius: touchedIndex == 3 ? 25.0 : 20.0,
      ));
    }

    return sections;
  }
}
