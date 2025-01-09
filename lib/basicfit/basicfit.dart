import 'dart:convert';
import 'dart:math';
import 'package:basicshare/basicfit/hardcodedgraphql.dart';
import 'package:basicshare/basicfit/types.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String IOS_CLIENT_ID = 'q6KqjlQINmjOC86rqt9JdU_i41nhD_Z4DwygpBxGiIs';
const String IOS_USER_AGENT =
    'Basic-Fit/2436 CFNetwork/1568.300.101 Darwin/24.2.0';
const String GRAPHQL_ACCESS_TOKEN = "wRd4zwNule_XU0IrbE-DSfF0IcFxSnDCilyboUhYLps";

const String BASE_ANDROID_URL = 'https://bfa.basic-fit.com/api';
const String BASE_URL = 'https://my.basic-fit.com';
const String BASE_LOGIN_URL = 'https://login.basic-fit.com';
const String BASE_AUTH_URL = 'https://auth.basic-fit.com';
const String BASE_GRAPHQL_URL = 'https://graphql.contentful.com/content/v1/spaces/ztnn01luatek/environments/master';

class BasicFit {
  final String bearerToken;

  BasicFit(this.bearerToken);

  Future<List<Visit>?> loadVisits() async {
    final Uri url = Uri.parse('$BASE_ANDROID_URL/member/gym-visits-total');

    final response = await http.get(
      url,
      headers: <String, String>{
        'User-Agent': IOS_USER_AGENT,
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> visits = decoded['visits'];
      return visits.map((visit) => Visit.fromJson(visit)).toList();
    }

    return [];
  }

  Future<Map<String, dynamic>?> loadInflux(String clubId) async {
    final Uri url = Uri.parse(BASE_GRAPHQL_URL);

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $GRAPHQL_ACCESS_TOKEN',
      },
      body: HARDCODED_GRAPHQL_REQUEST.replaceAll("%CLUB_ID%", clubId),
    );

    if (response.statusCode == 200) {
      final graphql = jsonDecode(response.body) as Map<String, dynamic>;
      return graphql['data']['clubCollection']['items'][0]['busynessData'];
    }

    return null;
  }

  Future<Member?> loadMember() async {
    final Uri url = Uri.parse('$BASE_ANDROID_URL/member/info');

    final response = await http.get(
      url,
      headers: <String, String>{
        'User-Agent': IOS_USER_AGENT,
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return Member.fromJson(decoded['member'] as Map<String, dynamic>);
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

  static String generateQrcodeData(String cardNumber, String deviceId) {
    final guid = generateOfflineGUID(); // we don't care about this because we're not checking if entry was successful
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final hashValue = hash(cardNumber, guid, time, deviceId);
    final finalValue = 'GM2:$cardNumber:$guid:$time:$hashValue';

    return finalValue;
  }
}

Future<Map<String, dynamic>?> code2token(
    String code, String codeVerifier) async {
  final String payload =
      'code=$code&code_verifier=$codeVerifier&redirect_uri=com.basicfit.bfa:/oauthredirect&client_id=$IOS_CLIENT_ID&grant_type=authorization_code';

  final Uri url = Uri.parse('$BASE_AUTH_URL/token');

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    body: payload,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  return null;
}

Future<Map<String, dynamic>?> refresh2token(
    String accessToken, String refreshToken) async {
  final String payload =
      'access_token=$accessToken&refresh_token=$refreshToken&redirect_uri=com.basicfit.bfa:/oauthredirect&client_id=$IOS_CLIENT_ID&grant_type=refresh_token';

  final Uri url = Uri.parse('$BASE_AUTH_URL/token');

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    body: payload,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  return null;
}

String buildOauthURL(String state, String codeChallenge) {
  return '$BASE_LOGIN_URL/?state=$state'
      '&response_type=code'
      '&code_challenge_method=S256'
      '&app=true'
      '&code_challenge=$codeChallenge'
      '&redirect_uri=com.basicfit.bfa:/oauthredirect'
      '&client_id=$IOS_CLIENT_ID'
      '&auto_login=true';
}
