import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/basicfit/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AuthState {
  final String accessToken;
  final String refreshToken;
  final BasicFit? basicFit;
  final Member? member;
  final List<Visit>? visits;
  final Map<String, dynamic>? todayInflux;

  AuthState({
    required this.accessToken,
    required this.refreshToken,
    this.basicFit,
    this.member,
    this.visits,
    this.todayInflux,
  });

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    BasicFit? basicFit,
    Member? member,
    List<Visit>? visits,
    Map<String, dynamic>? todayInflux,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      basicFit: basicFit ?? this.basicFit,
      member: member ?? this.member,
      visits: visits ?? this.visits,
      todayInflux: todayInflux ?? this.todayInflux,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(
          AuthState(
            accessToken: '',
            refreshToken: '',
            basicFit: null,
            member: null,
            visits: null,
            todayInflux: null,
          ),
        );

  Future<void> initialize(String accessToken, String refreshToken, BasicFit basicFit) async {
    state = state.copyWith(accessToken: accessToken, refreshToken: refreshToken, basicFit: basicFit);

    Member? member = await basicFit.loadMember();
    if (member == null) {
      return;
    }

    state = state.copyWith(member: member);

    final visits = await basicFit.loadVisits();
    if (visits != null) {
      state = state.copyWith(visits: visits);
    }

    final influx = await basicFit.loadInflux(member.homeClubId.toUpperCase());
    if (influx != null) {
      final todayDayInEnglish = DateFormat('EEEE', 'en_US').format(DateTime.now()).toLowerCase();
      final todayInflux = influx[todayDayInEnglish];
      state = state.copyWith(todayInflux: todayInflux);
    }
  }

  void setAccessToken(String value) {
    state = state.copyWith(accessToken: value);
  }

  void setRefreshToken(String value) {
    state = state.copyWith(refreshToken: value);
  }

  void setBasicFit(BasicFit newBasicFit) {
    state = state.copyWith(basicFit: newBasicFit);
  }

  void setMember(Member newMember) {
    state = state.copyWith(member: newMember);
  }

  void setVisits(List<Visit> newVisits) {
    state = state.copyWith(visits: newVisits);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());