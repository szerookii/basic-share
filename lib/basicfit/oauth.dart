import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;

String generateCodeVerifier() {
  final random = Random.secure();
  final values = List<int>.generate(32, (_) => random.nextInt(256));
  final base64String = base64UrlEncode(values);
  return base64String.replaceAll('=', '');
}

String generateCodeChallenge(String codeVerifier) {
  final bytes = utf8.encode(codeVerifier);
  final digest = crypto.sha256.convert(bytes);
  final base64String = base64UrlEncode(digest.bytes);
  return base64String.replaceAll('=', '');
}
