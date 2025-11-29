import 'dart:async';
import 'package:flutter/material.dart';
import 'package:server_site/about.dart';
import 'package:server_site/status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:server_site/supabase_config.dart';

SupabaseClient get supabase => Supabase.instance.client;

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _navigateSafely(Widget page) async {
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

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    final displayName = SupabaseConfig.getDisplayName(user);
    final avatarUrl = SupabaseConfig.getAvatarUrl(user);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SafeArea(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // server logo
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Image.network(
                  'https://i.ibb.co/4nkHpYDw/servercurrent.jpg',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
              ),

              // server name
              const Flexible(
                child: Text('FriendSMP75', overflow: TextOverflow.visible),
              ),
            ],
          ),
        ),

        // to open end drawer by default and for icon
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
            // header
            Container(
              height: 66,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.purple,
              child: const Text(
                'Current page: Gallery',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            // pages list (scrollable)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text('About', textAlign: TextAlign.center),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateSafely(const About());
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text('Status', textAlign: TextAlign.center),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateSafely(const Status());
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text(
                      'Gallery',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    selected: true,
                    selectedTileColor: Colors.purpleAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateSafely(const Gallery());
                    },
                  ),
                ],
              ),
            ),

            // Bottom greeting + login/logout button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (avatarUrl != null)
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(avatarUrl),
                            backgroundColor: Colors.transparent,
                          ),
                        if (avatarUrl != null) const SizedBox(width: 8),
                        Text(
                          ' Hello $displayName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 60,
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
                        await SupabaseConfig.loginWithDiscord();
                      } else {
                        await SupabaseConfig.logout();
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user == null
                              ? "Login with Discord"
                              : "Welcome, $displayName (Logout)",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'By logging in you must accept to terms and service',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: const Center(child: Text('Welcome to the Gallery app!')),
    );
  }
}
