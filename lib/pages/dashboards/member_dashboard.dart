import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:server_site/widgets/dashboardtitles.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bool isMobile = width < 700;
    final bool isTablet = width >= 700 && width < 1080;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Member Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Submit your memories for staff review and keep community highlights growing.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),

        GridView.count(
          crossAxisCount: isMobile
              ? 1
              : isTablet
              ? 2
              : 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile
              ? 1.95
              : isTablet
              ? 1.35
              : 1.4,
          padding: const EdgeInsets.all(8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DashboardTiles(
              title: 'Memories upload request',
              color: const Color(0xFF198A8E),
              icon: Icons.auto_stories_rounded,
              actionLabel: 'Request',
              onTap: () {
                context.push('/memories_request');
              },
              subText:
                  'Request staff to review and add your community memory to the public gallery.',
            ),
            DashboardTiles(
              title: 'Staff applications',
              color: const Color(0xFF6B5B95),
              icon: Icons.badge_rounded,
              actionLabel: 'Open',
              onTap: () {
                context.go('/member/application');
              },
              subText:
                  'View and submit applications for staff opportunities and review updates.',
            ),
          ],
        ),
      ],
    );
  }
}
