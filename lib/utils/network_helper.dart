import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworkHelper {
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkBasicFitConnectivity() async {
    try {
      final response = await http.head(Uri.parse('https://login.basic-fit.com'),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36'
          }).timeout(const Duration(seconds: 10));

      return response.statusCode < 400;
    } catch (e) {
      debugPrint("[*] Basic-Fit connectivity check failed: $e");
      return false;
    }
  }

  static Future<void> waitForConnectivity({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      if (await checkConnectivity()) {
        return;
      }

      debugPrint(
          "[*] No connectivity, waiting... (attempt ${i + 1}/$maxRetries)");
      await Future.delayed(const Duration(seconds: 2));
    }

    throw Exception("No network connectivity after $maxRetries attempts");
  }
}
