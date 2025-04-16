import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:basicshare/basicfit/hardcodedgraphql.dart';
import 'package:basicshare/basicfit/types.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String IOS_CLIENT_ID = 'q6KqjlQINmjOC86rqt9JdU_i41nhD_Z4DwygpBxGiIs';
const String IOS_USER_AGENT =
    'Basic-Fit/2436 CFNetwork/1568.300.101 Darwin/24.2.0';
const String IOS_REDIRECT_URI = 'com.basicfit.bfa:/oauthredirect';

const String ANDROID_CLIENT_ID = 'hMN33iw3DpHNg5VQaeNKoRUQKmIIvQV5vxOKba8AnrM';
const String ANDROID_USER_AGENT = 'Basic Fit App/1.76.0.2634 (Android)';
const String ANDROID_REDIRECT_URI = 'com.basicfit.trainingapp:/oauthredirect';

const String GRAPHQL_ACCESS_TOKEN =
    'wRd4zwNule_XU0IrbE-DSfF0IcFxSnDCilyboUhYLps';

const String BASE_ANDROID_URL = 'https://bfa.basic-fit.com/api';
const String BASE_URL = 'https://my.basic-fit.com';
const String BASE_LOGIN_URL = 'https://login.basic-fit.com';
const String BASE_AUTH_URL = 'https://auth.basic-fit.com';
const String BASE_GRAPHQL_URL =
    'https://graphql.contentful.com/content/v1/spaces/ztnn01luatek/environments/master';

String getPlatformClientId() {
  if (Platform.isAndroid) {
    return ANDROID_CLIENT_ID;
  }
  return IOS_CLIENT_ID;
}

String getPlatformRedirectUri() {
  if (Platform.isAndroid) {
    return ANDROID_REDIRECT_URI;
  }
  return IOS_REDIRECT_URI;
}

class BasicFit {
  final String bearerToken;

  BasicFit(this.bearerToken);

  Future<List<HealthMeasurement>> loadHealthMeasurements() async {
    final Uri url = Uri.parse('$BASE_ANDROID_URL/member/health/measurements');
    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'User-Agent':
              Platform.isAndroid ? ANDROID_USER_AGENT : IOS_USER_AGENT,
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        return decoded.map((e) => HealthMeasurement.fromJson(e)).toList();
      }
      debugPrint("[*] loadHealthMeasurements failed: ${response.statusCode}");
    } catch (e) {
      debugPrint("[*] loadHealthMeasurements error: $e");
    }
    return [];
  }

  Future<List<Visit>?> loadVisits() async {
    final Uri url = Uri.parse('$BASE_ANDROID_URL/member/gym-visits-total');

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'User-Agent':
              Platform.isAndroid ? ANDROID_USER_AGENT : IOS_USER_AGENT,
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> visits = decoded['visits'];
        return visits.map((visit) => Visit.fromJson(visit)).toList();
      }

      debugPrint("[*] Load visits failed with status: ${response.statusCode}");
    } catch (e) {
      debugPrint("[*] Load visits error: $e");
    }

    return [];
  }

  Future<Map<String, dynamic>?> loadInflux(String clubId) async {
    final Uri url = Uri.parse(BASE_GRAPHQL_URL);

    try {
      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $GRAPHQL_ACCESS_TOKEN',
            },
            body: HARDCODED_GRAPHQL_REQUEST.replaceAll("%CLUB_ID%", clubId),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final graphql = jsonDecode(response.body) as Map<String, dynamic>;
        return graphql['data']['clubCollection']['items'][0]['busynessData'];
      }

      debugPrint("[*] Load influx failed with status: ${response.statusCode}");
    } catch (e) {
      debugPrint("[*] Load influx error: $e");
    }

    return null;
  }

  Future<Member?> loadMember() async {
    final Uri url = Uri.parse('$BASE_ANDROID_URL/member/info');

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'User-Agent':
              Platform.isAndroid ? ANDROID_USER_AGENT : IOS_USER_AGENT,
          'Authorization': 'Bearer $bearerToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return Member.fromJson(decoded['member'] as Map<String, dynamic>);
      }

      if (response.statusCode == 401) {
        debugPrint(
            "[*] Token expired or invalid (401). Need to refresh token.");
        throw TokenExpiredException("Access token expired or invalid");
      }

      debugPrint("[*] Load member failed with status: ${response.statusCode}");
    } catch (e) {
      debugPrint("[*] Load member error: $e");
      rethrow;
    }

    return null;
  }

  static String generateOfflineGUID({int size = 3}) {
    const String charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    final random = Random();
    String result = "";

    for (int i = 0; i < size; i++) {
      result += charset[random.nextInt(charset.length)];
    }

    return result;
  }

  static String hash(String cardNbr, String guid, int time, String deviceId) {
    final input = '$cardNbr$guid$time$deviceId';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);

    return digest
        .toString()
        .substring(digest.toString().length - 8)
        .toUpperCase();
  }

  static String generateQrcodeData(
      String cardNumber, String deviceId, String? persistentGuid) {
    final guid = persistentGuid ?? generateOfflineGUID();
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final hashValue = hash(cardNumber, guid, time, deviceId);
    final finalValue = 'GM2:$cardNumber:$guid:$time:$hashValue';

    return finalValue;
  }

  static Future<bool> checkAccessResult(String guid, String cardNumber) async {
    final Uri url = Uri.parse(
        'https://access-result-storage.basic-fit.com/api/AccessControlResult?comId=$guid&card=$cardNumber');

    try {
      debugPrint("[*] Checking access result for GUID: $guid");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        return decoded.isNotEmpty;
      }

      debugPrint("[*] checkAccessResult failed: ${response.statusCode}");
    } catch (e) {
      debugPrint("[*] checkAccessResult error: $e");
    }

    return false;
  }
}

Future<Map<String, dynamic>?> code2token(
    String code, String codeVerifier) async {
  final String payload =
      'code=$code&code_verifier=$codeVerifier&redirect_uri=${getPlatformRedirectUri()}&client_id=${getPlatformClientId()}&grant_type=authorization_code';

  final Uri url = Uri.parse('$BASE_AUTH_URL/token');

  try {
    final response = await http
        .post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent':
                Platform.isAndroid ? ANDROID_USER_AGENT : IOS_USER_AGENT,
          },
          body: payload,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    debugPrint("[*] Token exchange failed with status: ${response.statusCode}");
    debugPrint("[*] Response body: ${response.body}");
  } catch (e) {
    debugPrint("[*] Token exchange error: $e");
  }

  return null;
}

Future<Map<String, dynamic>?> refresh2token(
    String accessToken, String refreshToken) async {
  final String payload =
      'access_token=$accessToken&refresh_token=$refreshToken&redirect_uri=${getPlatformRedirectUri()}&client_id=${getPlatformClientId()}&grant_type=refresh_token';

  final Uri url = Uri.parse('$BASE_AUTH_URL/token');

  try {
    final response = await http
        .post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent':
                Platform.isAndroid ? ANDROID_USER_AGENT : IOS_USER_AGENT,
          },
          body: payload,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    debugPrint("[*] Token refresh failed with status: ${response.statusCode}");
    debugPrint("[*] Response body: ${response.body}");
  } catch (e) {
    debugPrint("[*] Token refresh error: $e");
  }

  return null;
}

String buildOauthURL(String state, String codeChallenge) {
  return '$BASE_LOGIN_URL/?state=$state'
      '&response_type=code'
      '&code_challenge_method=S256'
      '&app=true'
      '&code_challenge=$codeChallenge'
      '&redirect_uri=${getPlatformRedirectUri()}'
      '&client_id=${getPlatformClientId()}'
      '&auto_login=true';
}
