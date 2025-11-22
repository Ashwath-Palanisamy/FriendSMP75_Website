import 'package:flutter/material.dart';
import 'package:server_site/about.dart';
import 'package:server_site/gallery.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Status extends StatefulWidget {
  const Status({super.key});

  @override
  State<Status> createState() => _StatusState();
}

class _StatusState extends State<Status> {
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
                'Current page: Status',
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
                    title: const Text(
                      'Status',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    selected: true,
                    selectedTileColor: Colors.purpleAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateSafely(const Status());
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text('Gallery', textAlign: TextAlign.center),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateSafely(const Gallery());
                    },
                  ),
                ],
              ),
            ),

            // bottom login button
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
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // close drawer first

                      final supabase = supabase.instance.client;

                      await supabase.auth.signInWithOAuth(
                        Provider.discord, // or Provider.google, Provider.github
                        redirectTo:
                            'io.supabase.flutter://login-callback/', // deep link
                      );

                      // Supabase will handle redirect → return to app
                      // You stay on the same Status page, but now user is logged in
                    },
                    child: const Text("Login with Discord"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: const Center(child: Text('Welcome to the Status app!')),
    );
  }
}
