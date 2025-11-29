import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SupabaseConfig {
  static SupabaseClient? _client;
  static StreamSubscription<AuthState>? _authSub;
  static bool _initialized = false;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception("Supabase not initialized yet. Call init() first.");
    }
    return _client!;
  }

  /// Fetch credentials from backend
  static Future<Map<String, String>?> fetchSupabaseDetails() async {
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
          print("Missing fields in response");
          return null;
        }
      } else {
        print("Unauthorized or failed. Status code ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching credentials: $e");
      return null;
    }
  }

  /// Initialize Supabase with fetched credentials
  static Future<void> init() async {
    if (_initialized) return;
    final details = await fetchSupabaseDetails();
    if (details != null) {
      await Supabase.initialize(
        url: details['url']!,
        anonKey: details['key']!,
      );
      _client = Supabase.instance.client;
      print("Supabase initialized with backend credentials");
    } else {
      throw Exception("Failed to fetch Supabase credentials");
    }
  }

  /// Start listening to auth state changes globally
  static void startAuthListener(void Function(AuthState) onChange) {
    _authSub = client.auth.onAuthStateChange.listen(onChange);
  }

  /// Stop listening
  static void stopAuthListener() {
    _authSub?.cancel();
    _authSub = null;
  }

  /// --- Helpers for user metadata ---

  /// Get a safe display name from user metadata
  static String getDisplayName(User? user) {
    if (user == null) return 'User';
    final meta = user.userMetadata;

    final rawName = meta?['name'];
    final rawUsername = meta?['username'];
    final rawUserName = meta?['user_name'];

    dynamic candidate = rawName ?? rawUsername ?? rawUserName;

    if (candidate is String) return candidate;
    if (candidate is List && candidate.isNotEmpty) {
      return candidate.first.toString();
    }
    if (candidate != null) return candidate.toString();

    return 'User';
  }

  /// Get avatar URL if provided by Discord OAuth
  static String? getAvatarUrl(User? user) {
    final meta = user?.userMetadata;
    return meta?['avatar_url'] as String?;
  }

  /// Quick login/logout helpers
  static Future<void> loginWithDiscord() async {
    await client.auth.signInWithOAuth(OAuthProvider.discord);
  }

  static Future<void> logout() async {
    await client.auth.signOut();
  }
}