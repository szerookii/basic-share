import 'package:basicshare/state/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

class VisitsPage extends ConsumerWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basicFit = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mes visites 🏋️",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5.w,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (basicFit.visits != null && basicFit.visits!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      basicFit.visits!.length > 10
                          ? "10 dernières visites"
                          : "${basicFit.visits!.length} visite${basicFit.visits!.length > 1 ? 's' : ''}",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                SizedBox(height: 2.h),
                if (basicFit.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child:
                          CircularProgressIndicator(color: Colors.deepOrange),
                    ),
                  )
                else if (basicFit.visits != null && basicFit.visits!.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: basicFit.visits!.length > 10
                        ? 10
                        : basicFit.visits!.length,
                    itemBuilder: (context, index) {
                      final visit = basicFit.visits![index];
                      final date = DateTime.parse(visit.swipeDateTime);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Row(
                            children: [
                              Container(
                                width: 14.w,
                                height: 14.w,
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: Colors.deepOrange,
                                  size: 6.w,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visit.clubName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.white38,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Aucune visite enregistrée",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
