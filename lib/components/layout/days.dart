import 'package:basicshare/state/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class WeekSelector extends ConsumerStatefulWidget {
  final List<DateTime> selectedDates;

  const WeekSelector({super.key, required this.selectedDates});

  @override
  WeekSelectorState createState() => WeekSelectorState();
}

class WeekSelectorState extends ConsumerState<WeekSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<DateTime> weekDates;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controller.forward();
    weekDates = getCurrentWeekDates();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> getCurrentWeekDates() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime startOfWeek = now.subtract(Duration(days: currentWeekday - 1));

    List<DateTime> weekDates = [];
    for (int i = 0; i < 7; i++) {
      weekDates.add(
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i));
    }
    return weekDates;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 2.h, bottom: 2.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'TA SEMAINE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                weekDates.length,
                (index) => _DayItem(
                  index: index,
                  isSelected: widget.selectedDates.any((date) =>
                      date.year == weekDates[index].year &&
                      date.month == weekDates[index].month &&
                      date.day == weekDates[index].day),
                  date: weekDates[index],
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Ton club: ${auth.member?.homeClub ?? 'Chargement...'}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayItem extends StatelessWidget {
  const _DayItem({
    required this.index,
    required this.isSelected,
    required this.date,
  });

  final int index;
  final bool isSelected;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // Set the locale to French
    String dayName = DateFormat('E', 'fr').format(date);
    String dayNumber = DateFormat('d').format(date);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Colors.grey[200]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: isSelected ? Colors.deepOrange : Colors.grey[300]!,
          width: 0.5.w,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        children: [
          Text(
            dayNumber,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          Text(
            dayName,
            style: TextStyle(
              fontSize: 10.sp,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
