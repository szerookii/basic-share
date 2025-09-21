import 'package:basicshare/components/modals/friend_qrcode.dart';
import 'package:basicshare/state/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sizer/sizer.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mes amis 👥",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5.w,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (auth.friends != null)
                          Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Text(
                              auth.friends!.isNotEmpty
                                  ? "${auth.friends!.length} ami${auth.friends!.length > 1 ? 's' : ''}"
                                  : "Aucun ami",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Fonctionnalité à venir !"),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Icon(
                              Icons.person_add_rounded,
                              color: Colors.deepOrange,
                              size: 6.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                if (auth.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child:
                          CircularProgressIndicator(color: Colors.deepOrange),
                    ),
                  )
                else if (auth.friends != null && auth.friends!.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: auth.friends!.length,
                    itemBuilder: (context, index) {
                      final friend = auth.friends![index];
                      return _buildFriendCard(context, friend, index);
                    },
                  )
                else
                  _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, friend, int index) {
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
                color: _getAvatarColors(index)[0].withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getInitials(friend.firstNameG, friend.lastNameG),
                  style: TextStyle(
                    color: _getAvatarColors(index)[0],
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${friend.firstNameG ?? ''} ${friend.lastNameG ?? ''}"
                        .trim(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    friend.email ?? 'Email non disponible',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _showFriendOptions(context, friend);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.deepOrange,
                      size: 5.w,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 10.h),
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Colors.white38,
          ),
          SizedBox(height: 2.h),
          Text(
            "Aucun ami enregistré",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getAvatarColors(int index) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.deepOrange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return [colors[index % colors.length]];
  }

  String _getInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials.isEmpty ? '?' : initials;
  }

  void _showFriendOptions(BuildContext context, friend) async {
    final cardNumber = friend.activeCardsG?.isNotEmpty == true
        ? friend.activeCardsG!.first.cardNumber
        : null;

    if (cardNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Numéro de carte non disponible"),
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }

    final friendName =
        "${friend.firstNameG ?? ''} ${friend.lastNameG ?? ''}".trim();

    await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FriendQrcodeModal(
          friendName: friendName,
          cardNumber: cardNumber,
        );
      },
    );

    await ScreenBrightness.instance.resetApplicationScreenBrightness();
  }
}
