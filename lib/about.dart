import 'package:flutter/material.dart';
import 'package:server_site/gallery.dart';
import 'package:server_site/status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

SupabaseClient get supabase => Supabase.instance.client;

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to auth state changes
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel(); // cancel subscription when widget is disposed
    super.dispose();
  }



  Future<void> _navigateSafely(Widget page) async {
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(seconds: 15),
        reverseTransitionDuration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loginWithDiscord() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.discord);
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    setState(() {}); // refresh UI
  }

  /// Helper to safely extract display name
  String _getUserData(User? user) {
    if (user == null) return 'User';
    final meta = user.userMetadata;

    final rawName = meta?['name'];
    final rawUserName = meta?['user_name'];
    final rawUsername = meta?['username'];

    dynamic candidate = rawName ?? rawUserName ?? rawUsername;

    if (candidate is String) return candidate;
    if (candidate is List && candidate.isNotEmpty) {
      return candidate.first.toString();
    }
    if (candidate != null) return candidate.toString();

    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final displayName = _getUserData(user);

    // Debug print to see actual metadata
    print("User metadata: ${user?.userMetadata}");

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SafeArea(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Image.network(
                  'https://i.ibb.co/4nkHpYDw/servercurrent.jpg',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
              ),
              const Flexible(
                child: Text('FriendSMP75', overflow: TextOverflow.visible),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),

      endDrawer: Drawer(
        child: Column(
          children: [
            // Header
            Container(
              height: 66,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.purple,
              child: const Text(
                'Current page: About',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            // Pages list (scrollable)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text(
                      'About',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    selected: true,
                    selectedTileColor: Colors.purpleAccent,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text('Status', textAlign: TextAlign.center),
                    onTap: () {
                      _navigateSafely(const Status());
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text('Gallery', textAlign: TextAlign.center),
                    onTap: () {
                      _navigateSafely(const Gallery());
                    },
                  ),
                ],
              ),
            ),

            // Bottom login button (adapted safely)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (user == null) {
                        await _loginWithDiscord();
                      } else {
                        await _logout();
                      }
                    },
                    child: Text(
                      user == null
                          ? "Login with Discord"
                          : "👋 Welcome, $displayName (Logout)",
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: const Center(child: Text('Welcome to the About app!')),
    );
  }
}
