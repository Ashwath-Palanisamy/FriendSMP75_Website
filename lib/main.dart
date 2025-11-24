import 'dart:async';

import 'package:flutter/material.dart';
import 'package:server_site/about.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, String>?> fetchsupabasedetails() async {
  const backendUrl =
      'https://key-backend-for-friendsmp75-website.onrender.com/secure-data';
  const accessToken = 'ybjyyfusdhhdtfvsckbcksdufhcgsjhcmnnxgcjbcn';

  try {
    final response = await http.get(
      Uri.parse(backendUrl),
      headers: {'X-Access-Token': accessToken},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final supabaseUrl = data['supabase_url'] as String?;
      final supabaseKey = data['supabase_key'] as String?;

      if (supabaseUrl != null && supabaseKey != null) {
        return {'url': supabaseUrl, 'key': supabaseKey};
      } else {
        final error = "Missing fields in response";
        print(error);
        return null;
      }
    } else {
      final unAuthorized =
          "Unauthorized or failed to connect. Status code ${response.statusCode}";
      print(unAuthorized);
      return null;
    }
  } catch (e) {
    final error = "Error fetching credentials: $e";
    print(error);
    return null;
  }
}

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

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: About(),
    );
  }
}
