import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:server_site/data/backend_config.dart';
import 'package:server_site/data/supabase_config.dart';
import 'package:server_site/widgets/appbar.dart';
import 'package:server_site/widgets/footer.dart';
import 'package:server_site/widgets/nav_drawer.dart';

class StaffApplication extends StatefulWidget {
  const StaffApplication({super.key});

  @override
  State<StaffApplication> createState() => _StaffApplicationState();
}

class _StaffApplicationState extends State<StaffApplication> {
  late Future<bool> _appStatusFuture;
  late Future<List<dynamic>> _applicationsFuture;
  bool _isUpdatingStatus = false;

  String? _cachedOwnerUid;
  final Map<String, TextEditingController> _explanationControllers = {};

  @override
  void initState() {
    super.initState();
    _appStatusFuture = BackendData.getStaffAppStatus();
    _applicationsFuture = BackendData.fetchSubmittedApplications();
    _loadOwnerContext();
  }

  @override
  void dispose() {
    for (var controller in _explanationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOwnerContext() async {
    try {
      final ownerId = await BackendData.getOwnerAuthID();
      if (mounted) {
        setState(() {
          _cachedOwnerUid = ownerId;
        });
      }
    } catch (e) {
      // Suppress schema cache misses (e.g. public.profiles not found)
      if (!e.toString().contains('PGRST205')) {
        debugPrint('Error loading owner configuration parameters: $e');
      }
    }
  }

  Future<void> setStaffAppstatus(bool state) async {
    if (_isUpdatingStatus) return;

    try {
      setState(() {
        _isUpdatingStatus = true;
      });
      await BackendData.updateStaffAppStatus(state);
      if (!mounted) return;
      setState(() {
        _appStatusFuture = BackendData.getStaffAppStatus();
        _isUpdatingStatus = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
      debugPrint('Error when passing staff application status');
    }
  }

  Future<void> _submitVote(String appUid, String voteType) async {
    try {
      await BackendData.submitStaffVote(appUid, voteType);

      if (!mounted) return;
      setState(() {
        _applicationsFuture = BackendData.fetchSubmittedApplications();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered your $voteType evaluation vote.')),
      );
    } catch (e) {
      debugPrint('Error routing vote interaction through backend context: $e');
    }
  }

  Future<void> _finalDecision(String appUid, String decision) async {
    final explanation = _explanationControllers[appUid]?.text ?? '';
    if (explanation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter an explanation before finalizing decisions.',
          ),
        ),
      );
      return;
    }

    try {
      await BackendData.finalizeStaffApplication(appUid, decision, explanation);

      if (!mounted) return;
      setState(() {
        _applicationsFuture = BackendData.fetchSubmittedApplications();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Application has been successfully marked as $decision.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error writing final resolution sequence parameters out: $e');
    }
  }

  List<Widget> _buildUserAnswers(dynamic rawAnswers) {
    try {
      List<dynamic> list = (rawAnswers is String)
          ? jsonDecode(rawAnswers)
          : (rawAnswers is List ? rawAnswers : []);

      String extractedUsername = 'Unknown Candidate';
      final userField = list.firstWhere(
        (item) =>
            item is Map && (item['label'] ?? '').toLowerCase() == 'username',
        orElse: () => null,
      );
      if (userField != null) {
        extractedUsername =
            userField['value']?.toString() ?? 'Unknown Candidate';
      }

      List<Widget> widgets = [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Candidate Username',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  extractedUsername,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];

      widgets.addAll(
        list
            .where((item) {
              if (item is! Map) return false;
              final String type = item['type'] ?? '';
              final String label = (item['label'] ?? '').toLowerCase();
              return type != 'HIDDEN_FIELDS' &&
                  !label.contains('username') &&
                  !label.contains('user_uid');
            })
            .map<Widget>((item) {
              final String label = item['label'] ?? '';
              dynamic value = item['value'];
              String display = '';

              if (item['type'] == 'MULTIPLE_CHOICE' && value is List) {
                final List options = item['options'] ?? [];
                display = options
                    .where((o) => value.contains(o['id']))
                    .map((o) => o['text'])
                    .join(', ');
              } else {
                display = value?.toString() ?? 'No Response';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        display,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              );
            }),
      );

      return widgets;
    } catch (e) {
      return [
        Text(
          'Error parsing form data: $e',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    final bool isMobile = MediaQuery.sizeOf(context).width < 760;
    final bool isOwner =
        user != null && _cachedOwnerUid != null && user.id == _cachedOwnerUid;

    if (user == null) {
      return Scaffold(
        appBar: AppbarPage(backArrow: true),
        endDrawer: NavDrawer(currentPage: 'Dashboard', parentContext: context),
        body: const Column(
          children: [
            Expanded(
              child: Center(
                child: Text('Login required to access staff pages.'),
              ),
            ),
            MyFooter(),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppbarPage(backArrow: true),
      endDrawer: NavDrawer(currentPage: 'Dashboard', parentContext: context),
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
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 20,
                  16,
                  isMobile ? 12 : 20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Page Header ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staff Application Admin',
                            style: TextStyle(
                              fontSize: isMobile ? 30 : 40,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage and review community submissions.',
                            style: TextStyle(
                              color: Colors.blueGrey[100],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── App Status / Owner Controls ───────────────────────
                    FutureBuilder<bool>(
                      future: _appStatusFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E7AA7),
                              ),
                            ),
                          );
                        }
                        final isOpen = snapshot.data ?? false;
                        if (isOwner) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFF1B3556).withValues(
                                      alpha: 0.3,
                                    )
                                  : Colors.redAccent.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isOpen
                                    ? Colors.blueAccent.withValues(alpha: 0.4)
                                    : Colors.redAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.admin_panel_settings,
                                      color: Colors.amberAccent,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Owner Controls',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[50],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOpen
                                            ? Colors.green.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.red.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isOpen ? 'OPEN' : 'CLOSED',
                                        style: TextStyle(
                                          color: isOpen
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isOpen
                                          ? Colors.redAccent
                                          : const Color(0xFF1E7AA7),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: _isUpdatingStatus
                                        ? null
                                        : () => setStaffAppstatus(!isOpen),
                                    child: Text(
                                      isOpen
                                          ? 'Close Application'
                                          : 'Open Application',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOpen
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.lock_outline_rounded,
                                color: isOpen
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isOpen
                                    ? 'Applications Status: Open'
                                    : 'Applications Status: Closed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── Submitted Applications ────────────────────────────
                    const Text(
                      'Submitted Applications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<bool>(
                      future: _appStatusFuture,
                      builder: (context, statusSnapshot) {
                        final isOpen = statusSnapshot.data ?? false;
                        if (!isOpen) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.01),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Center(
                              child: Text(
                                'Applications must be open to process reviews.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            ),
                          );
                        }
                        return FutureBuilder<List<dynamic>>(
                          future: _applicationsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final data = snapshot.data ?? [];
                            if (data.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                  child: Text('No applications submitted yet.'),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: data.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final app =
                                    data[index] as Map<String, dynamic>;
                                final String appUid = app['user_id'] ?? '';
                                final dynamic rawAnswers =
                                    app['answers'] ?? '[]';
                                final String currentStatus =
                                    app['status'] ?? 'pending';

                                final List<dynamic> answersList =
                                    (rawAnswers is String)
                                    ? jsonDecode(rawAnswers)
                                    : rawAnswers;
                                final userField = answersList.firstWhere(
                                  (item) =>
                                      item is Map &&
                                      (item['label'] ?? '').toLowerCase() ==
                                          'username',
                                  orElse: () => {'value': 'Unknown Candidate'},
                                );
                                final String username =
                                    userField['value']?.toString() ??
                                    'Unknown Candidate';

                                final List<dynamic> yesVotesList =
                                    app['voted_yes_uids'] ?? [];
                                final List<dynamic> noVotesList =
                                    app['voted_no_uids'] ?? [];
                                final int yesVotes = yesVotesList.length;
                                final int noVotes = noVotesList.length;

                                final bool hasVotedYes =
                                    yesVotesList.contains(user.id);
                                final bool hasVotedNo =
                                    noVotesList.contains(user.id);

                                _explanationControllers.putIfAbsent(
                                  appUid,
                                  () => TextEditingController(),
                                );

                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111E2F),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ExpansionTile(
                                    childrenPadding:
                                        const EdgeInsets.all(16),
                                    collapsedBackgroundColor:
                                        Colors.transparent,
                                    backgroundColor: Colors.transparent,
                                    iconColor: Colors.white54,
                                    collapsedIconColor: Colors.white38,
                                    // ── Collapsed header ─────────────────
                                    title: Row(
                                      children: [
                                        if (currentStatus != 'pending') ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: currentStatus == 'APPROVED'
                                                  ? Colors.green.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : Colors.red.withValues(
                                                      alpha: 0.2,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              currentStatus,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: currentStatus ==
                                                        'APPROVED'
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'UUID: $appUid',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white38,
                                      ),
                                    ),
                                    // ── Animated arrow + vote count ───────
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '+$yesVotes / -$noVotes',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                    // Default trailing arrow is kept (animated)
                                    // ── Expanded content ──────────────────
                                    children: [
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Form Answers:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ..._buildUserAnswers(rawAnswers),
                                      const Divider(
                                        color: Colors.white12,
                                        height: 24,
                                      ),
                                      if (isOwner) ...[
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.groups_rounded,
                                              color: Colors.amberAccent,
                                              size: 20,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Staff Team Review',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amberAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller:
                                              _explanationControllers[appUid],
                                          maxLines: 2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Provide the official staff team reasoning/explanation...',
                                            hintStyle: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13,
                                            ),
                                            filled: true,
                                            fillColor: Colors.black12,
                                            contentPadding:
                                                const EdgeInsets.all(12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Colors.white24,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green
                                                    .withValues(alpha: 0.15),
                                                foregroundColor:
                                                    Colors.greenAccent,
                                              ),
                                              onPressed: () => _finalDecision(
                                                appUid,
                                                'APPROVED',
                                              ),
                                              icon: const Icon(
                                                Icons.check,
                                                size: 16,
                                              ),
                                              label: const Text('Approve'),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red
                                                    .withValues(alpha: 0.15),
                                                foregroundColor:
                                                    Colors.redAccent,
                                              ),
                                              onPressed: () => _finalDecision(
                                                appUid,
                                                'DENIED',
                                              ),
                                              icon: const Icon(
                                                Icons.close,
                                                size: 16,
                                              ),
                                              label: const Text('Deny'),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Cast Your Vote:',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 13,
                                              ),
                                            ),
                                            _buildVoteButtons(
                                              appUid,
                                              hasVotedYes,
                                              hasVotedNo,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 40),
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

  Widget _buildVoteButtons(String targetUid, bool activeYes, bool activeNo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: activeYes
                ? Colors.greenAccent.withValues(alpha: 0.4)
                : Colors.green.withValues(alpha: 0.15),
            foregroundColor: activeYes ? Colors.white : Colors.greenAccent,
          ),
          icon: const Icon(Icons.thumb_up_rounded, size: 18),
          onPressed: () => _submitVote(targetUid, 'YES'),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: activeNo
                ? Colors.redAccent.withValues(alpha: 0.4)
                : Colors.red.withValues(alpha: 0.15),
            foregroundColor: activeNo ? Colors.white : Colors.redAccent,
          ),
          icon: const Icon(Icons.thumb_down_rounded, size: 18),
          onPressed: () => _submitVote(targetUid, 'NO'),
        ),
      ],
    );
  }
}