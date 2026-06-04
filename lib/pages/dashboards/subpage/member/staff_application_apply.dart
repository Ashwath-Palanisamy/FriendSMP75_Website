import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:server_site/widgets/appbar.dart';
import 'package:server_site/widgets/nav_drawer.dart';
import 'package:server_site/widgets/footer.dart';
import 'package:server_site/data/backend_config.dart';
import 'package:server_site/data/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Web-only imports for iframe embedding
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui;
import 'package:pointer_interceptor/pointer_interceptor.dart';

class StaffApplicationApply extends StatefulWidget {
  const StaffApplicationApply({super.key});

  @override
  State<StaffApplicationApply> createState() => _StaffApplicationApplyState();
}

class _StaffApplicationApplyState extends State<StaffApplicationApply> {
  StreamSubscription<AuthState>? _authSub;
  bool _loading = true;
  bool _isOpen = false;

  // 🛑 SUBMISSION TRACKING STATES
  bool _hasApplied = false;
  bool _isStaff = false;
  String _applicationStatus = 'Pending';

  // Single tracking point for the initialized Iframe target source
  String _activeTallyUrl = '';

  static const String _discordUrl = 'https://discord.gg/K8ucVvjfge';
  static const String _tallyBaseUrl =
      'https://tally.so/embed/KYkZ5K?alignLeft=1&hideTitle=1&transparentBackground=1&dynamicHeight=1';

  String _buildTallyUrl(String? userId, String username) {
    final uri = Uri.parse(_tallyBaseUrl);
    final queryParameters = <String, String>{
      ...uri.queryParameters,
      if (userId != null && userId.isNotEmpty) 'user_uid': userId,
      if (username.isNotEmpty && username != 'Community Member')
        'username': username,
    };
    return uri.replace(queryParameters: queryParameters).toString();
  }

  @override
  void initState() {
    super.initState();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        final session = data.session;
        if (session == null) {
          setState(() {
            _activeTallyUrl = '';
            _hasApplied = false;
            _isStaff = false;
          });
        } else {
          _initPage();
        }
      }
    });

    _initPage();
  }

  Future<void> _initPage() async {
  setState(() => _loading = true);

  final open = await BackendData.getStaffAppStatus();
  final user = SupabaseConfig.client.auth.currentUser;

  // ── Staff check ──────────────────────────────────────────
  if (user != null) {
    final staffUuids = await BackendData.getUUID();
    if (staffUuids != null) {
      _isStaff = staffUuids.any((entry) =>
    entry['staff_uid']?.toString() == user.id);
    }
  }

  // 🛑 CHECK SUBMISSION STATUS (skip for staff)
  if (user != null && !_isStaff) {
    final appCheck = await BackendData.getStaffApplicationStatus();
    if (appCheck != null) {
      final String returnedUid = appCheck['user_id']?.toString() ?? '';
      _hasApplied = returnedUid == user.id;

      if (_hasApplied) {
        final rawStatus = appCheck['status']?.toString() ?? 'pending';
        _applicationStatus =
            rawStatus.substring(0, 1).toUpperCase() +
            rawStatus.substring(1);
      }
    }
  }

  if (mounted) {
    final String resolvedUsername =
        user?.userMetadata?['custom_claims']?['global_name'] ??
        user?.userMetadata?['full_name'] ??
        user?.email ??
        'Community Member';

    setState(() {
      _isOpen = open;
      _activeTallyUrl = _buildTallyUrl(user?.id, resolvedUsername);
      _loading = false;
    });

    if (kIsWeb && user != null && _isOpen && !_hasApplied && !_isStaff) {
      _registerTallyIframe('tally-form');
    }
  }
}

  void _registerTallyIframe(String viewType) {
    try {
      ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.sandbox.value = 'allow-scripts allow-same-origin allow-forms';
        iframe.src = _activeTallyUrl;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        return iframe;
      });
    } catch (e) {
      // Ignored - system avoids factory conflicts during hot reloads
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
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

  Color _getStatusColor() {
    switch (_applicationStatus.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2ECC71);
      case 'rejected':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFFF1C40F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 700;
    final double width =
        isMobile ? MediaQuery.sizeOf(context).width - 24 : 980;
    final user = SupabaseConfig.client.auth.currentUser;

    final String discordUsername =
        user?.userMetadata?['custom_claims']?['global_name'] ??
        user?.userMetadata?['full_name'] ??
        user?.email ??
        'Community Member';

    return Scaffold(
      appBar: AppbarPage(customTitle: 'Staff Application', backArrow: true),
      endDrawer: PointerInterceptor(
        child: NavDrawer(
          currentPage: 'Staff Application',
          parentContext: context,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF091323), Color(0xFF102037), Color(0xFF091323)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 20,
                  18,
                  isMobile ? 12 : 20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B3556), Color(0xFF17506F)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staff Application',
                            style: TextStyle(
                              fontSize: isMobile ? 28 : 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Apply to join the FriendSMP75 staff team. Read rules in Discord and follow announcements for updates.',
                            style: TextStyle(
                              color: Colors.blueGrey[100],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- STATE EVALUATION AND CONDITIONAL RENDERING ---
                    if (_loading)
                      Center(
                        child: Container(
                          height: 220,
                          width: width,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else if (user == null || _activeTallyUrl.isEmpty)
                      Container(
                        width: width,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'You must be logged in to apply',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please sign in with Discord to continue.',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                FilledButton(
                                  onPressed: () async {
                                    await SupabaseConfig.loginWithDiscord();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2A6DE0),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Sign in with Discord'),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: _openDiscord,
                                  child: const Text('Open Discord'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else if (_isStaff)
                      Container(
                        width: width,
                        padding: EdgeInsets.all(isMobile ? 20 : 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF111E2F),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.amberAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Staff Member',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2ECC71,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF2ECC71,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'APPROVED',
                                    style: TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 24),
                            const SizedBox(height: 6),
                            Text(
                              'Hey $discordUsername,',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You are already an approved member of the FriendSMP75 staff team. Your application was accepted and you are part of the team!',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Application Status: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2ECC71,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF2ECC71,
                                        ).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Approved',
                                      style: TextStyle(
                                        color: Color(0xFF2ECC71),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: _openDiscord,
                              icon: const Icon(Icons.launch, size: 16),
                              label: const Text('Open Discord'),
                            ),
                          ],
                        ),
                      )
                    else if (_hasApplied)
                      Container(
                        width: width,
                        padding: EdgeInsets.all(isMobile ? 20 : 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF111E2F),
                          border: Border.all(color: Colors.white12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.assignment_turned_in,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Application Received',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 24),
                            const SizedBox(height: 6),
                            Text(
                              'Hey $discordUsername,',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have already submitted an application for the FriendSMP75 staff team. Our administration group is carefully reviewing your answers!',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Review Status: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor().withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _getStatusColor().withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _applicationStatus,
                                      style: TextStyle(
                                        color: _getStatusColor(),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: _openDiscord,
                              icon: const Icon(Icons.launch, size: 16),
                              label: const Text(
                                'Check Announcements on Discord',
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!_isOpen)
                      Container(
                        width: width,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Applications are currently closed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Staff applications are closed right now. Please watch for updates in our Discord or announcements.',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                FilledButton(
                                  onPressed: _openDiscord,
                                  child: const Text('Open Discord'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/announcements');
                                  },
                                  child: const Text('View Announcements'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: isMobile ? 820 : 780,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          child: kIsWeb
                              ? PointerInterceptor(
                                  child: HtmlElementView(
                                    viewType: 'tally-form',
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Open the application form'),
                                      const SizedBox(height: 8),
                                      FilledButton(
                                        onPressed: () async {
                                          final Uri url = Uri.parse(
                                            _activeTallyUrl,
                                          );
                                          await launchUrl(
                                            url,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },
                                        child: const Text('Open Form'),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                    const SizedBox(height: 20),
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