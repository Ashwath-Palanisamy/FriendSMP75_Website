import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:server_site/pages/dashboards/subpage/member/memories_request.dart';
import 'package:server_site/pages/dashboards/subpage/member/staff_application_apply.dart';
import 'package:server_site/pages/dashboards/subpage/staff/staff_application.dart';
import 'package:server_site/pages/dashboards/subpage/staff/staff_server_access.dart';
import 'package:server_site/pages/home.dart';
import 'package:server_site/pages/about.dart';
import 'package:server_site/pages/announcement.dart';
import 'package:server_site/pages/dashboard.dart';
import 'package:server_site/pages/gallery.dart';
import 'package:server_site/pages/status.dart';
import 'package:server_site/pages/support_us.dart';
import 'package:server_site/pages/thank_you.dart';
import 'package:server_site/pages/votes.dart';
import 'package:server_site/pages/dashboards/subpage/staff/staff_announcement.dart';
import 'package:server_site/pages/dashboards/subpage/staff/staff_dm_broadcast.dart';
import 'package:server_site/pages/dashboards/subpage/staff/staff_gallary.dart';
import 'package:server_site/pages/dashboards/subpage/staff/staff_gallery_requests.dart';
import 'package:server_site/sub_page/view_announcements.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Home(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const About(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/announcements',
        name: 'announcements',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ListAnnouncements(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/announcement/:title',
        name: 'view-announcement',
        pageBuilder: (context, state) {
          final title = Uri.decodeComponent(
            state.pathParameters['title'] ?? '',
          );
          // Accept Map<String, dynamic> for extra, fallback to empty string if not present
          String body = '';
          if (state.extra != null) {
            if (state.extra is Map) {
              final map = state.extra as Map;
              if (map['body'] is String) {
                body = map['body'] as String;
              }
            } else if (state.extra is String) {
              body = state.extra as String;
            }
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: ViewAnnouncement(title: title, body: body),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Dashboard(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Gallery(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/status',
        name: 'status',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Status(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SupportUsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/votes',
        name: 'votes',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VotePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/thank-you',
        name: 'thank-you',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ThankYouPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(path: '/Thank-you', redirect: (context, state) => '/thank-you'),
      GoRoute(
        path: '/staff/announcements',
        name: 'staff-announcements',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Staffannouncements(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/staff/gallery',
        name: 'staff-gallery',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffGallary(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/staff/gallery-requests',
        name: 'staff-gallery-requests',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffGalleryRequestsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      
      GoRoute(
        path: '/staff/dm-broadcast',
        name: 'staff-dm-broadcast',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffDmBroadcastPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/memories_request',
        name: 'memories_request',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MemoriesRequest(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: '/staff/server-access',
        name: 'server-access',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffServerAccess(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: '/staff/application',
        name: 'staff-application',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffApplication(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: '/member/application',
        name: 'staff-application-apply',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffApplicationApply(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
