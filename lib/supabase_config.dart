import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';


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

SupabaseClient get supabase => Supabase.instance.client;