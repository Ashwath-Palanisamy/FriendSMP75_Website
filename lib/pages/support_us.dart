import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:server_site/widgets/appbar.dart';
import 'package:server_site/widgets/footer.dart';
import 'package:server_site/widgets/nav_drawer.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

class SupportUsPage extends StatefulWidget {
  const SupportUsPage({super.key});

  @override
  State<SupportUsPage> createState() => _SupportUsPageState();
}

class _SupportUsPageState extends State<SupportUsPage> {
  final String _razorpayViewType = 'razorpay-donate-button';
  final String _razorpayContainerId = 'razorpay-button-container';
  static bool _viewsRegistered = false;

  void _handleRazorpayReturn() {
    final params = Uri.base.queryParameters;
    final status = params['razorpay_payment_link_status']?.toLowerCase();

    final hasRazorpaySignal =
        params.containsKey('payment_id') ||
        params.containsKey('razorpay_payment_id') ||
        params.containsKey('razorpay_signature') ||
        params.containsKey('razorpay_payment_link_id');

    if (hasRazorpaySignal && (status == null || status == 'paid')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.go('/thank-you');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _handleRazorpayReturn();

    if (_viewsRegistered) {
      return;
    }

    ui.platformViewRegistry.registerViewFactory(_razorpayViewType, (
      int viewId,
    ) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = _razorpayContainerId;
      div.style.setProperty('width', '100%');
      div.style.setProperty('display', 'flex');
      div.style.setProperty('justify-content', 'center');
      div.style.setProperty('pointer-events', 'none');

      final form = web.document.createElement('form') as web.HTMLFormElement;
      final script =
          web.document.createElement('script') as web.HTMLScriptElement;
      script.src = 'https://checkout.razorpay.com/v1/payment-button.js';
      script.setAttribute('data-payment_button_id', 'pl_SgRAbsZyCxGVjO');
      script.setAttribute(
        'data-redirect_url',
        '${Uri.base.origin}/#/thank-you',
      );
      script.async = true;

      form.append(script);
      div.append(form);

      return div;
    });

    _viewsRegistered = true;
  }

  @override
  void dispose() {
    final razorpayElement = web.document.getElementById(_razorpayContainerId);
    razorpayElement?.remove();
    super.dispose();
  }

  Widget _buildSupportItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(fontSize: 18, color: Color(0xFF43D3E2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      appBar: AppbarPage(customTitle: 'FriendSMP75 - Support us'),
      endDrawer: NavDrawer(currentPage: 'Support us', parentContext: context),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A1423), Color(0xFF102036), Color(0xFF0A1423)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 20,
                  18,
                  isMobile ? 12 : 20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2B395F), Color(0xFF214E6F)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support FriendSMP75',
                            style: TextStyle(
                              fontSize: isMobile ? 30 : 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your support keeps hosting running and helps us improve maps, plugins, and events.',
                            style: TextStyle(
                              color: Colors.blueGrey[100],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Why support us?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        Whylist(
                          text: 'Server hosting and infrastructure costs',
                          icon: Icons.cloud_done_rounded,
                        ),
                        Whylist(
                          text: 'Plugins, tools, and quality-of-life upgrades',
                          icon: Icons.extension_rounded,
                        ),
                        Whylist(
                          text: 'Developers and map creators',
                          icon: Icons.handyman_rounded,
                        ),
                        Whylist(
                          text: 'Keeping the server online long-term',
                          icon: Icons.favorite_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF2A4A7F)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How Your Support Helps',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Every contribution directly impacts the quality of your FriendSMP75 experience:',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSupportItem(
                            '🖥️ Server Stability',
                            'Ensures 24/7 uptime with reliable hosting infrastructure',
                          ),
                          _buildSupportItem(
                            '🎮 New Features',
                            'Funds plugin development and gameplay enhancements',
                          ),
                          _buildSupportItem(
                            '🗺️ World Management',
                            'Supports custom maps, creative builds, and events',
                          ),
                          _buildSupportItem(
                            '👥 Community',
                            'Enables staff support and player moderation tools',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Support Through Ads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF43D3E2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We keep ad placements limited and only on content pages. Viewing an ad helps us pay for uptime and new features.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              height: 160,
                              width: 320,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Advertisements removed',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Support Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF43D3E2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose how you want to support FriendSMP75:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildOption(
                            '💰 Direct Support',
                            'Provide direct funding for server operations',
                          ),
                          _buildOption(
                            '🎯 Supporter Perks',
                            'Get exclusive in-game benefits and recognition',
                          ),
                          _buildOption(
                            '📺 View Ads',
                            'Contribute by viewing ads - 100% goes to the server',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Donate Securely',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF43D3E2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.7),
                              ),
                            ),
                            child: const Text(
                              'TESTING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Use the button below to make a direct contribution through Razorpay.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'After a successful payment, you will be redirected to the Thank You page.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Button is disabled in testing mode.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: SizedBox(
                              width: 360,
                              height: 110,
                              child: HtmlElementView(
                                viewType: _razorpayViewType,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          'Viewing ads takes just a few minutes and helps tremendously!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          'Thank you for keeping FriendSMP75 alive! 💜',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
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

class Whylist extends StatelessWidget {
  final String text;
  final IconData icon;
  const Whylist({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF43D3E2)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
