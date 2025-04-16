import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LineChartSample2 extends StatefulWidget {
  final List<FlSpot>? lineData;

  const LineChartSample2({super.key, this.lineData});

  @override
  State<LineChartSample2> createState() => _LineChartSample2State();
}

class _LineChartSample2State extends State<LineChartSample2> {
  List<Color> gradientColors = [
    Colors.orangeAccent,
    Colors.orangeAccent.shade700,
  ];

  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 2.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "AFFLUENCE AUJOURD'HUI",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                AspectRatio(
                  aspectRatio: 2,
                  child: LineChart(
                    mainData(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0h';
        break;
      case 4:
        text = '4h';
        break;
      case 8:
        text = '8h';
        break;
      case 12:
        text = '12h';
        break;
      case 16:
        text = '16h';
        break;
      case 20:
        text = '20h';
        break;
      case 23:
        text = '23h';
        break;
      default:
        text = '';
        break;
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style, textAlign: TextAlign.left),
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: const FlGridData(
        show: false,
      ),
      borderData: FlBorderData(
        show: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      minX: -1,
      maxX: 24,
      minY: 0,
      maxY: 5,
      lineBarsData: [
        LineChartBarData(
          spots: widget.lineData ?? [],
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot spot) {
              return LineTooltipItem(
                'Heure: ${spot.x.toInt()}h',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
