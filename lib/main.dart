import 'package:flutter/material.dart';
import 'package:server_site/about.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:server_site/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(MyApp());
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
    return MaterialApp(
      title: 'FriendSMP75',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: About(),
    );
  }
}
