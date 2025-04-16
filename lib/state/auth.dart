import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/basicfit/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final String accessToken;
  final String refreshToken;
  final BasicFit? basicFit;
  final Member? member;
  final List<Visit>? visits;
  final List<HealthMeasurement>? healthMeasurements;
  final Map<String, dynamic>? todayInflux;
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
    this.todayInflux,
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
    Map<String, dynamic>? todayInflux,
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
      todayInflux: todayInflux ?? this.todayInflux,
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
            todayInflux: null,
            errorMessage: null,
            isLoading: false,
          ),
        );

  Future<void> initialize(
      String accessToken, String refreshToken, BasicFit basicFit) async {
    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      basicFit: basicFit,
      isLoading: true,
      errorMessage: null,
    );

    try {
      Member? member = await basicFit.loadMember();
      if (member == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              "Impossible de charger les informations du membre. Certaines fonctionnalités peuvent être limitées.",
        );
        debugPrint("[*] Warning: Could not load member information");
        return;
      }

      state = state.copyWith(member: member);

      try {
        final visits = await basicFit.loadVisits();
        if (visits != null) {
          state = state.copyWith(visits: visits);
        }
      } catch (e) {
        debugPrint("[*] Warning: Could not load visits: $e");
      }

      try {
        final influx =
            await basicFit.loadInflux(member.homeClubId.toUpperCase());
        if (influx != null) {
          final todayDayInEnglish =
              DateFormat('EEEE', 'en_US').format(DateTime.now()).toLowerCase();
          final todayInflux = influx[todayDayInEnglish];
          state = state.copyWith(todayInflux: todayInflux);
        }
      } catch (e) {
        debugPrint("[*] Warning: Could not load influx data: $e");
      }

      try {
        final healthMeasurements = await basicFit.loadHealthMeasurements();
        state = state.copyWith(healthMeasurements: healthMeasurements);
      } catch (e) {
        debugPrint("[*] Warning: Could not load health measurements: $e");
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Erreur lors du chargement des données: $e",
      );
      debugPrint("[*] Error during initialization: $e");
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

  Future<void> retryLoadMember() async {
    if (state.basicFit == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      Member? member = await state.basicFit!.loadMember();
      if (member == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Impossible de charger les informations du membre",
        );
        return;
      }

      state = state.copyWith(member: member, isLoading: false);

      try {
        final visits = await state.basicFit!.loadVisits();
        if (visits != null) {
          state = state.copyWith(visits: visits);
        }
      } catch (e) {
        debugPrint("[*] Warning: Could not load visits during retry: $e");
      }

      try {
        final influx =
            await state.basicFit!.loadInflux(member.homeClubId.toUpperCase());
        if (influx != null) {
          final todayDayInEnglish =
              DateFormat('EEEE', 'en_US').format(DateTime.now()).toLowerCase();
          final todayInflux = influx[todayDayInEnglish];
          state = state.copyWith(todayInflux: todayInflux);
        }
      } catch (e) {
        debugPrint("[*] Warning: Could not load influx data during retry: $e");
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        await _handleTokenExpired();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Erreur lors du rechargement: $e",
        );
        debugPrint("[*] Error during member reload: $e");
      }
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

        await retryLoadMember();
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
