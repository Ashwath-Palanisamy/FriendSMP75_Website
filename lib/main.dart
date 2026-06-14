import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:server_site/data/supabase_config.dart';
import 'package:server_site/router/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  usePathUrlStrategy();
  runApp(const MyApp());
}

SupabaseClient get supabase => Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    SupabaseConfig.startAuthListener((authstate) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    SupabaseConfig.stopAuthListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF1AA7B8),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF101A2B),
          surfaceContainerHighest: const Color(0xFF1A2740),
          primary: const Color(0xFF43D3E2),
          secondary: const Color(0xFFFFB060),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
    );

    return MaterialApp.router(
      title: 'FriendSMP75',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1320),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1320),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF121E33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF162845),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
