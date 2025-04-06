import 'package:basicshare/basicfit/basicfit.dart';
import 'package:basicshare/state/auth.dart';
import 'package:basicshare/views/dashboard.dart';
import 'package:basicshare/views/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/date_symbol_data_local.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  /*QuickSettings.setup(
    onTileAdded: (tile) {
      debugPrint('[*] Tile added: $tile');
      tile.label = 'BasicShare';
      tile.subtitle = 'Afficher le QRCode';
      return tile;
    },
  );*/

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final dataProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  String? accessToken = prefs.getString('access_token');
  String? refreshToken = prefs.getString('refresh_token');
  final expires = prefs.getInt('expires');

  debugPrint('[*] accessToken: $accessToken');
  debugPrint('[*] refreshToken: $refreshToken');
  debugPrint('[*] expires: $expires');

  if (accessToken == null || refreshToken == null || expires == null) {
    throw Exception('No tokens found');
  } else {
    if ((DateTime.now().millisecondsSinceEpoch / 1000).floor() > expires) {
      debugPrint('[*] Token expired, trying to refresh');

      final token = await refresh2token(accessToken, refreshToken);

      if (token == null) {
        throw Exception('Failed to refresh token');
      }

      final newAccessToken = token['access_token'];
      final newRefreshToken = token['refresh_token'];
      final expires = token['expires_in'];

      if (newAccessToken == null ||
          newRefreshToken == null ||
          expires == null) {
        throw Exception('Failed to get new tokens');
      }

      debugPrint('[*] Token refreshed');
      debugPrint('[*] New access token: $newAccessToken');
      debugPrint('[*] New refresh token: $newRefreshToken');
      debugPrint('[*] New expires: $expires');

      await prefs.setString('access_token', newAccessToken);
      await prefs.setString('refresh_token', newRefreshToken);
      await prefs.setInt('expires', expires);

      accessToken = newAccessToken;
      refreshToken = newRefreshToken;
    }

    final basicFit = BasicFit(accessToken as String);
    await ref
        .read(authNotifierProvider.notifier)
        .initialize(accessToken, refreshToken as String, basicFit);

    return true;
  }
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);

    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
          title: 'BasicShare',
          theme: ThemeData.dark(),
          home: data.when(
            data: (value) => const DashboardPage(),
            loading: () =>
                const Center(child: SpinKitThreeBounce(color: Colors.white)),
            error: (error, stack) {
              debugPrint('[*] Error: $error');
              return const LoginPage();
            },
          ));
    });
  }
}
