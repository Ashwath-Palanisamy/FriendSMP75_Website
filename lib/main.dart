import 'package:flutter/material.dart';
import 'package:server_site/about.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:server_site/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final credentials = await fetchsupabasedetails();
  if (credentials != null) {
    await Supabase.initialize(
      anonKey: credentials['key']!,
      url: credentials['url']!,
    );
  } else {
    print("Failed to get data from backend");
  }

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
