import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/basicfit/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final String accessToken;
  final String refreshToken;
  final BasicFit? basicFit;
  final Member? member;

  AuthState({
    required this.accessToken,
    required this.refreshToken,
    this.basicFit,
    this.member,
  });

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    BasicFit? basicFit,
    Member? member,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      basicFit: basicFit ?? this.basicFit,
      member: member ?? this.member,
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
          ),
        );

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
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());