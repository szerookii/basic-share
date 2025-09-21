import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/basicfit/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final String accessToken;
  final String refreshToken;
  final BasicFit? basicFit;
  final Member? member;
  final List<Visit>? visits;
  final List<HealthMeasurement>? healthMeasurements;
  final List<Friend>? friends;
  final Map<String, dynamic>? todayInflux;
  final String? sessionCookie;
  final String? errorMessage;
  final bool isLoading;
  final String? persistentGuid;

  AuthState({
    required this.accessToken,
    required this.refreshToken,
    this.basicFit,
    this.member,
    this.visits,
    this.healthMeasurements,
    this.friends,
    this.todayInflux,
    this.sessionCookie,
    this.errorMessage,
    this.isLoading = false,
    this.persistentGuid,
  });

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    BasicFit? basicFit,
    Member? member,
    List<Visit>? visits,
    List<HealthMeasurement>? healthMeasurements,
    List<Friend>? friends,
    Map<String, dynamic>? todayInflux,
    String? sessionCookie,
    String? errorMessage,
    bool? isLoading,
    String? persistentGuid,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      basicFit: basicFit ?? this.basicFit,
      member: member ?? this.member,
      visits: visits ?? this.visits,
      healthMeasurements: healthMeasurements ?? this.healthMeasurements,
      friends: friends ?? this.friends,
      todayInflux: todayInflux ?? this.todayInflux,
      sessionCookie: sessionCookie ?? this.sessionCookie,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      persistentGuid: persistentGuid ?? this.persistentGuid,
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
            healthMeasurements: null,
            friends: null,
            todayInflux: null,
            sessionCookie: null,
            errorMessage: null,
            isLoading: false,
          ),
        );

  Future<void> initialize(String accessToken, String refreshToken) async {
    final basicFit = BasicFit(accessToken);
    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      basicFit: basicFit,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final member = await basicFit.loadMember();
      state = state.copyWith(member: member);

      // Get session cookie for friends API
      final sessionCookie = await token2session(accessToken);
      state = state.copyWith(sessionCookie: sessionCookie);

      // Load additional data
      final visits = await basicFit.loadVisits();
      final healthMeasurements = await basicFit.loadHealthMeasurements();

      List<Friend>? friends;
      try {
        friends = await basicFit.loadFriends(sessionCookie: sessionCookie);
      } catch (e) {
        debugPrint("[*] Warning: Could not load friends: $e");
      }

      Map<String, dynamic>? todayInflux;
      if (member != null) {
        todayInflux = await basicFit.loadTodayInflux(member.homeClubId);
      }

      state = state.copyWith(
        visits: visits,
        healthMeasurements: healthMeasurements,
        friends: friends,
        todayInflux: todayInflux,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Erreur: $e",
      );
    }
  }

  void setAccessToken(String value) {
    state = state.copyWith(accessToken: value);
  }

  void setRefreshToken(String value) {
    state = state.copyWith(refreshToken: value);
  }

  Future<void> refreshTokens() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _handleTokenExpired();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Erreur lors du rafraîchissement: $e",
      );
      debugPrint("[*] Error during token refresh: $e");
    }
  }

  Future<void> _handleTokenExpired() async {
    debugPrint("[*] Handling token expiration...");

    try {
      final tokenData =
          await refresh2token(state.accessToken, state.refreshToken);

      if (tokenData != null && tokenData['access_token'] != null) {
        final newAccessToken = tokenData['access_token'];
        final newRefreshToken =
            tokenData['refresh_token'] ?? state.refreshToken;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("access_token", newAccessToken);
        await prefs.setString("refresh_token", newRefreshToken);

        final newBasicFit = BasicFit(newAccessToken);

        state = state.copyWith(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          basicFit: newBasicFit,
        );

        debugPrint("[*] Token refreshed successfully");
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Session expirée. Veuillez vous reconnecter.",
        );
      }
    } catch (e) {
      debugPrint("[*] Error refreshing token: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Session expirée. Veuillez vous reconnecter.",
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String getOrCreatePersistentGuid() {
    if (state.persistentGuid == null) {
      final newGuid = BasicFit.generateOfflineGUID();
      state = state.copyWith(persistentGuid: newGuid);
      return newGuid;
    }
    return state.persistentGuid!;
  }

  void regeneratePersistentGuid() {
    final newGuid = BasicFit.generateOfflineGUID();
    state = state.copyWith(persistentGuid: newGuid);
  }

  Future<bool> checkAndConfirmEntry() async {
    if (state.member == null || state.persistentGuid == null) {
      return false;
    }

    final isConfirmed = await BasicFit.checkAccessResult(
        state.persistentGuid!, state.member!.cardnumber);

    if (isConfirmed) {
      regeneratePersistentGuid();
    }

    return isConfirmed;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
