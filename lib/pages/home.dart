import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:server_site/data/backend_config.dart';
import 'package:server_site/widgets/announcement_preview.dart';
import 'package:server_site/widgets/appbar.dart';
import 'package:server_site/widgets/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:server_site/data/supabase_config.dart';
import 'package:server_site/widgets/nav_drawer.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

SupabaseClient get supabase => Supabase.instance.client;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  StreamSubscription<AuthState>? _authSub;
  List<dynamic> announcements = [];
  Map<String, dynamic> announcement = {};
  static const String _serverIp = 'friendsmp75.xubi.org';
  static const String _discordUrl = 'https://discord.gg/K8ucVvjfge';

  @override
  void initState() {
    super.initState();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
    _getAnnouncement();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void copyIP() {
    Clipboard.setData(const ClipboardData(text: _serverIp));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.lightBlue),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text('Server IP copied to clipboard'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDiscord() async {
    final Uri url = Uri.parse(_discordUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Discord link')),
      );
    }
  }

  Future<void> _getAnnouncement() async {
    final result = await BackendData.getAnnouncements();
    if (result != null && result.isNotEmpty) {
      setState(() {
        announcements = result.reversed.toList();
        announcement = announcements[0] as Map<String, dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    SupabaseConfig.getUserName(user);
    final width = MediaQuery.sizeOf(context).width;
    final bool isMobile = width < 700;

    return Scaffold(
      appBar: AppbarPage(),
      endDrawer: NavDrawer(currentPage: 'Home', parentContext: context),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B111A), Color(0xFF101B2B), Color(0xFF0B111A)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 22,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0E2A3D), Color(0xFF173A58)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 26,
                            offset: Offset(0, 14),
                            color: Color(0x44000000),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FriendSMP75',
                            style: TextStyle(
                              fontSize: isMobile ? 28 : 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jump in with friends, build your base, and stay updated with the latest server news.',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.blueGrey[100],
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _ActionCard(
                                icon: Icons.memory_rounded,
                                title: 'Server IP',
                                subtitle: _serverIp,
                                actionLabel: 'Copy IP',
                                onTap: copyIP,
                              ),
                              _ActionCard(
                                icon: Icons.discord,
                                title: 'Community Discord',
                                subtitle: 'Chat, support, and events',
                                actionLabel: 'Join Discord',
                                onTap: _openDiscord,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    _SectionCard(
                      title: 'Recent Announcement',
                      child: announcement.isNotEmpty
                          ? LatestAnnouncementPreview(
                              announcement: announcement,
                            )
                          : const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                    ),

                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        context.push('/announcements');
                      },
                      icon: const Icon(Icons.history_edu_rounded),
                      label: const Text('Browse Older Announcements'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6DE0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const _SectionCard(
                      title: 'Frequently Asked Questions',
                      child: Column(
                        children: [
                          Faq(
                            question: 'How to claim land',
                            answer:
                                'To protect your builds, use a Golden Shovel to mark out a rectangle. Right-click the ground to set the first corner, then move to the opposite corner and right-click again to finalize the claim.',
                          ),
                          SizedBox(height: 10),
                          Faq(
                            question: 'How to reset password',
                            answer:
                                'If you are already logged into the server, use /changepass to change your password. If you are not logged in, please contact us through a support ticket so we can help.',
                          ),
                          SizedBox(height: 10),
                          Faq(
                            question: 'How old is the server',
                            answer:
                                'FriendSMP75 was founded in 2020, during the COVID-19 period.',
                          ),
                          SizedBox(height: 10),
                          Faq(
                            question:
                                'How to make ticket for reports and support',
                            answer:
                                'Tickets can be created on discord by visiting "tickets and reports" channel and clicking the button. When the button is clicked a new channel will be created and will ping staff members to help with your request',
                          ),
                          SizedBox(height: 10),
                          Faq(
                            question: 'What if i get banned? [Minecraft]',
                            answer:
                                'If you think you are banned unfairly you are welcome to create a ticket and share what happened with us on discord. If you are banned for breaking the rules please keep in mind creating a ticket won\'t help you, and you must accept the punishment given by staff member and staff\'s decision is final',
                          ),
                          SizedBox(height: 10),
                          Faq(
                            question: 'What if i get banned [Discord]',
                            answer:
                                'If you are temporarily banned please wait till you are unbanned automatically. If you are banned unfairly you are allowed to reach directly to owner via Email (Email to: friendsmp75@outlook.com), only one email is allowed for request if you believe the email was ignored you can request another unban after 14 days.\n\n If you received an response email stating you will be banned you can\'t request another unban request. ',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 42),
                    const MyFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Faq extends StatelessWidget {
  final String question;
  final String answer;
  const Faq({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        backgroundColor: const Color(0x1FFFFFFF),
        collapsedBackgroundColor: const Color(0x14FFFFFF),
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white,
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 240 : 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: Color(0x331A7CFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.lightBlueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
