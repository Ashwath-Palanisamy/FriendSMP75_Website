// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SupabaseConfig {
  static SupabaseClient? _client;
  static StreamSubscription<AuthState>? _authSub;
  static final bool _initialized = false;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception("Supabase not initialized yet. Call init() first.");
    }
    return _client!;
  }

  /// Fetch credentials from backend
  static Future<Map<String, String>?> fetchSupabaseDetails() async {
    const backendUrl =
        'https://key-backend-for-friendsmp75-website.vercel.app/secure-data';
    const accessToken = String.fromEnvironment("ACCESS_TOKEN");

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
      await Supabase.initialize(url: details['url']!, publishableKey: details['key']!);
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

  /// Get a safe username from user metadata
  static String getUserName(User? user) {
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

  // Get user's display name
  static String getDisplayName(User? user) {
    try {
      if (user == null) return 'user';
      final meta = user.userMetadata;
      final customClaims = meta?['custom_claims'];
      final displayName = customClaims?['global_name'];
      if (displayName is String && displayName.isNotEmpty) {
        return displayName;
      }
      return 'user';
    } catch (e) {
      return 'Error: $e';
    }
  }

  static String getSupabaseUUID(User? user) {
    return user?.id ?? 'Not logged in';
  }

  static String getDiscordId(User? user) {
    if (user == null) return 'Unknown';

    final meta = user.userMetadata;
    final customClaims = meta?['custom_claims'];

    final dynamic directDiscordId = meta?['discord_id'];
    final dynamic providerId = meta?['provider_id'];
    final dynamic customDiscordId = customClaims?['discord_id'];
    final dynamic customProviderId = customClaims?['provider_id'];
    final dynamic subject = customClaims?['sub'];

    final candidates = [
      directDiscordId,
      providerId,
      customDiscordId,
      customProviderId,
      subject,
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final text = candidate.toString().trim();
      final isNumeric =
          text.isNotEmpty &&
          text.codeUnits.every((code) => code >= 48 && code <= 57);
      if (isNumeric && text.length >= 17 && text.length <= 20) {
        return text;
      }
    }

    return 'Unknown';
  }

  /// Quick login/logout helpers
  static Future<void> loginWithDiscord() async {
    const String isDev = String.fromEnvironment(
      "IS_DEV",
      defaultValue: "false",
    );

    final String redirectUrl = isDev == "true"
        ? "http://localhost:8080/"
        : "https://friendsmp75.vercel.app/";

    await client.auth.signInWithOAuth(
      OAuthProvider.discord,
      redirectTo: redirectUrl,
    );
  }

  static Future<void> logout() async {
    await client.auth.signOut();
  }
}
