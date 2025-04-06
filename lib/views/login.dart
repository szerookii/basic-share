import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/basicfit/oauth.dart';
import 'package:basicshare/state/auth.dart';
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
          if (!request.url
                  .toString()
                  .contains("com.basicfit.bfa:/oauthredirect?") &&
              !request.method.toString().contains("POST")) {
            return;
          }

          final uri = Uri.parse(request.url.toString());
          final code = uri.queryParameters["code"];

          if (code == null) {
            return;
          }

          debugPrint("[*] Received code: $code");

          final token =
              await code2token(code, codeVerifier) as Map<String, dynamic>;
          final accessToken = token["access_token"];
          final refreshToken = token["refresh_token"];
          final expires = token["expires_in"];

          if (accessToken == null || refreshToken == null || expires == null) {
            return;
          }

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("access_token", accessToken);
          await prefs.setString("refresh_token", refreshToken);
          await prefs.setInt("expires", expires);

          BasicFit basicFit = BasicFit(accessToken);
          await ref.read(authNotifierProvider.notifier).initialize(accessToken, refreshToken, basicFit);

          Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
        },
        onWebViewCreated: (controller) async {
          CookieManager cookieManager = CookieManager.instance();
          await cookieManager.deleteAllCookies();

          debugPrint("[*] Code Verifier: $codeVerifier");
          debugPrint("[*] State: $state");
          debugPrint("[*] Code Challenge: $codeChallenge");
          debugPrint("[*] OAuth URL: $oauthUri");

          controller.loadUrl(urlRequest: URLRequest(url: WebUri(oauthUri)));
        },
        initialSettings: InAppWebViewSettings(
          sharedCookiesEnabled: false,
          thirdPartyCookiesEnabled: false,
          clearCache: true,
          clearSessionCache: true,
          transparentBackground: true,
        ),
      ),
    ));
  }
}