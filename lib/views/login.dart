import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/basicfit/oauth.dart';
import 'package:basicshare/state/auth.dart';
import 'package:basicshare/utils/network_helper.dart';
import 'package:basicshare/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeVerifier = generateCodeVerifier();
    final state = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final oauthUri = buildOauthURL(state, codeChallenge);

    return Scaffold(
        body: SafeArea(
      child: InAppWebView(
        onReceivedError: (controller, request, error) async {
          debugPrint("[*] Error: $error");

          if (error.type == WebResourceErrorType.TIMEOUT) {
            debugPrint("[*] Timeout detected - attempting retry...");
            await Future.delayed(Duration(seconds: 2));
            controller.reload();
            return;
          }
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url!;
          debugPrint("[*] Navigating to: ${uri.toString()}");

          if (uri
                  .toString()
                  .startsWith("com.basicfit.trainingapp:/oauthredirect?") ||
              uri.toString().startsWith("com.basicfit.bfa:/oauthredirect?")) {
            final code = uri.queryParameters["code"];

            if (code == null) {
              debugPrint("[*] No authorization code found in redirect");
              return NavigationActionPolicy.CANCEL;
            }

            debugPrint("[*] Received code: $code");

            try {
              final token =
                  await code2token(code, codeVerifier) as Map<String, dynamic>;
              final accessToken = token["access_token"];
              final refreshToken = token["refresh_token"];
              final expires = token["expires_in"];

              if (accessToken == null ||
                  refreshToken == null ||
                  expires == null) {
                debugPrint("[*] Invalid token response");
                return NavigationActionPolicy.CANCEL;
              }

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("access_token", accessToken);
              await prefs.setString("refresh_token", refreshToken);
              await prefs.setInt("expires", expires);

              BasicFit basicFit = BasicFit(accessToken);
              await ref
                  .read(authNotifierProvider.notifier)
                  .initialize(accessToken, refreshToken, basicFit);

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardPage()));
            } catch (e) {
              debugPrint("[*] Error during token exchange: $e");
            }

            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
        onWebViewCreated: (controller) async {
          CookieManager cookieManager = CookieManager.instance();
          await cookieManager.deleteAllCookies();

          debugPrint("[*] Code Verifier: $codeVerifier");
          debugPrint("[*] State: $state");
          debugPrint("[*] Code Challenge: $codeChallenge");
          debugPrint("[*] OAuth URL: $oauthUri");

          try {
            await NetworkHelper.waitForConnectivity(maxRetries: 3);
            debugPrint("[*] Network connectivity confirmed");
          } catch (e) {
            debugPrint("[*] Network connectivity issue: $e");
          }

          controller.loadUrl(urlRequest: URLRequest(url: WebUri(oauthUri)));
        },
        initialSettings: InAppWebViewSettings(
          sharedCookiesEnabled: false,
          thirdPartyCookiesEnabled: false,
          clearCache: true,
          clearSessionCache: true,
          transparentBackground: true,
          allowFileAccess: false,
          allowUniversalAccessFromFileURLs: true,
          allowFileAccessFromFileURLs: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          networkAvailable: true,
          javaScriptEnabled: true,
          supportMultipleWindows: false,
          userAgent:
              'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36',
        ),
      ),
    ));
  }
}
