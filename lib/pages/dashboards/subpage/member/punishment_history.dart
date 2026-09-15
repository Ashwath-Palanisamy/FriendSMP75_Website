import 'dart:async';
import 'package:flutter/material.dart';
import 'package:server_site/data/backend_config.dart';
import 'package:server_site/widgets/appbar.dart';
import 'package:server_site/data/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PunishmentList extends StatefulWidget {
  const PunishmentList({super.key});

  @override
  State<PunishmentList> createState() => _PunishmentListState();
}

class _PunishmentListState extends State<PunishmentList> {
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<AuthState>? _authSub;

  bool _loading = true;
  bool _hasSearched = false;
  bool _isLoading = false;

  List<dynamic> _punishments = [];
  int _totalWarnings = 0;
  int _totalPunishments = 0;

  // Filter state: 'ALL', 'WARNING', 'PUNISHMENT'
  String _selectedFilter = 'ALL';

  // Pagination state
  int _currentPage = 1;
  static const int _pageSize = 5;

  static const String _discordUrl = 'https://discord.gg/K8ucVvjfge';

  @override
  void initState() {
    super.initState();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _searchController.dispose();
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

  /// Parses date string or Unix timestamp for sorting comparison
  DateTime _parseRecordDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);

    final String str = dateValue.toString();

    // Try parsing ISO-8601 (e.g. 2026-09-15)
    DateTime? parsed = DateTime.tryParse(str);
    if (parsed != null) return parsed;

    // Try parsing DD/MM/YYYY or DD-MM-YYYY
    final parts = str.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _fetchPunishmentsForPlayer(String username) async {
    if (username.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _punishments = [];
        _totalWarnings = 0;
        _totalPunishments = 0;
        _selectedFilter = 'ALL';
        _currentPage = 1;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final result = await BackendData.getPunishmentsForPlayer(username.trim());

      if (result is Map<String, dynamic>) {
        List<dynamic> records = List.from(
          result['records'] as List<dynamic>? ?? [],
        );

        // Sort records in descending order (Newest -> Oldest)
        records.sort((a, b) {
          final dateA = _parseRecordDate(
            a['created_at'] ?? a['date'] ?? a['formatted_date'],
          );
          final dateB = _parseRecordDate(
            b['created_at'] ?? b['date'] ?? b['formatted_date'],
          );
          return dateB.compareTo(dateA);
        });

        setState(() {
          _punishments = records;
          _totalWarnings = result['total_warnings'] as int? ?? 0;
          _totalPunishments = result['total_punishments'] as int? ?? 0;
          _selectedFilter = 'ALL';
          _currentPage = 1;
          _isLoading = false;
        });
      } else {
        _resetSearchData();
      }
    } catch (e) {
      _resetSearchData();
    }
  }

  void _resetSearchData() {
    setState(() {
      _punishments = [];
      _totalWarnings = 0;
      _totalPunishments = 0;
      _selectedFilter = 'ALL';
      _currentPage = 1;
      _isLoading = false;
    });
  }

  // Filtered list based on active category chip
  List<dynamic> get _filteredPunishments {
    if (_selectedFilter == 'WARNING') {
      return _punishments.where((item) {
        final category = item['category']?.toString().toUpperCase() ?? '';
        final type = item['type']?.toString().toUpperCase() ?? '';
        return category == 'WARNING' || type == 'WARN';
      }).toList();
    } else if (_selectedFilter == 'PUNISHMENT') {
      return _punishments.where((item) {
        final category = item['category']?.toString().toUpperCase() ?? '';
        final type = item['type']?.toString().toUpperCase() ?? '';
        return category != 'WARNING' && type != 'WARN';
      }).toList();
    }
    return _punishments;
  }

  // Slice list according to selected page
  List<dynamic> get _paginatedPunishments {
    final filtered = _filteredPunishments;
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + _pageSize < filtered.length)
        ? startIndex + _pageSize
        : filtered.length;
    return filtered.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    final count = _filteredPunishments.length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  Color _getPunishmentColor(String category, String type) {
    final String upperType = type.toUpperCase();
    if (category == 'WARNING' || upperType == 'WARN') return Colors.orange;
    if (upperType.contains('BAN')) return Colors.redAccent;
    if (upperType.contains('MUTE')) return Colors.amber;
    if (upperType.contains('KICK')) return Colors.blueAccent;
    return Colors.purpleAccent;
  }

  IconData _getPunishmentIcon(String category, String type) {
    final String upperType = type.toUpperCase();
    if (category == 'WARNING' || upperType == 'WARN') {
      return Icons.warning_amber_rounded;
    }
    if (upperType.contains('BAN')) return Icons.block;
    if (upperType.contains('MUTE')) return Icons.mic_off;
    if (upperType.contains('KICK')) return Icons.exit_to_app;
    return Icons.gavel;
  }

  Widget _buildStatChip({
    required String label,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required int count,
  }) {
    final bool isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterKey;
            _currentPage = 1;
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final totalPages = _totalPages;
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Page $_currentPage of $totalPages',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    final displayList = _paginatedPunishments;

    return Scaffold(
      appBar: AppbarPage(backArrow: true),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : user == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You must be logged in',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please sign in with Discord to look up player punishments.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
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
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Input
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Type in the player's username...",
                        prefixIcon: const Icon(Icons.person_search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchPunishmentsForPlayer('');
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _fetchPunishmentsForPlayer(
                                _searchController.text,
                              ),
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                      ),
                      onSubmitted: (value) => _fetchPunishmentsForPlayer(value),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _fetchPunishmentsForPlayer('');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Main Content
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : !_hasSearched
                          ? const Center(
                              child: Text(
                                "Type in the player's username to see their punishments",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : _punishments.isEmpty
                          ? const Center(
                              child: Text(
                                'This player has clean records!',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                // Quick Summary Badges
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildStatChip(
                                      label: "Warnings",
                                      count: "$_totalWarnings",
                                      color: Colors.orange,
                                      icon: Icons.warning_amber_rounded,
                                    ),
                                    _buildStatChip(
                                      label: "Punishments",
                                      count: "$_totalPunishments",
                                      color: Colors.redAccent,
                                      icon: Icons.gavel_rounded,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Category Filter Chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildFilterChip(
                                      label: 'All',
                                      filterKey: 'ALL',
                                      count: _punishments.length,
                                    ),
                                    _buildFilterChip(
                                      label: 'Warnings',
                                      filterKey: 'WARNING',
                                      count: _totalWarnings,
                                    ),
                                    _buildFilterChip(
                                      label: 'Punishments',
                                      filterKey: 'PUNISHMENT',
                                      count: _totalPunishments,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Paginated Records List
                                Expanded(
                                  child: displayList.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No ${_selectedFilter.toLowerCase()} found for this player.',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 15,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: displayList.length,
                                          itemBuilder: (context, index) {
                                            final item = displayList[index];

                                            final String category =
                                                item['category']?.toString() ??
                                                'PUNISHMENT';
                                            final String type =
                                                item['type']?.toString() ??
                                                'WARN';
                                            final String reason =
                                                item['reason']?.toString() ??
                                                'No reason provided';
                                            final String date =
                                                item['formatted_date']
                                                    ?.toString() ??
                                                'N/A';
                                            final bool active =
                                                item['active'] == 1 ||
                                                item['active'] == true;

                                            final Color themeColor =
                                                _getPunishmentColor(
                                                  category,
                                                  type,
                                                );
                                            final IconData typeIcon =
                                                _getPunishmentIcon(
                                                  category,
                                                  type,
                                                );

                                            return Card(
                                              elevation: 1,
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: themeColor.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: themeColor
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        typeIcon,
                                                        color: themeColor,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: themeColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.2,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  type.toUpperCase(),
                                                                  style: TextStyle(
                                                                    color:
                                                                        themeColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ),
                                                              if (category !=
                                                                  'WARNING')
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        active
                                                                        ? Colors.red.withValues(
                                                                            alpha:
                                                                                0.2,
                                                                          )
                                                                        : Colors.green.withValues(
                                                                            alpha:
                                                                                0.2,
                                                                          ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          6,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    active
                                                                        ? 'ACTIVE'
                                                                        : 'EXPIRED',
                                                                    style: TextStyle(
                                                                      color:
                                                                          active
                                                                          ? Colors.redAccent
                                                                          : Colors.green,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            reason,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                size: 12,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                date,
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                _buildPaginationBar(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
