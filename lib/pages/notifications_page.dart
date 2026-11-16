import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/notification_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;
  String? errorMessage;

  String selectedFilter = 'All';

  static const Color primary = Color(0xFF4220E5);
  static const Color background = Color(0xFFF8F9FF);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color muted = Color(0xFF474556);

  final List<String> filters = [
    'All',
    'Tasks',
    'Team',
    'AI Insights',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Please sign in to view notifications.';
      });
      return;
    }

    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load notifications.';
      });
    }
  }

  int get unreadCount {
    return notifications.where((item) {
      return item['is_read'] != true;
    }).length;
  }

  String _getCategory(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString().toLowerCase();

    switch (type) {
      case 'task':
      case 'tasks':
      case 'task_assigned':
      case 'milestone':
      case 'achievement':
        return 'Tasks';

      case 'team':
      case 'invitation':
      case 'team_invitation':
      case 'group':
        return 'Team';

      case 'ai':
      case 'ai_insight':
        return 'AI Insights';

      default:
        return 'Other';
    }
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (selectedFilter == 'All') {
      return notifications;
    }

    return notifications.where((item) {
      return _getCategory(item) == selectedFilter;
    }).toList();
  }

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    if (notification['is_read'] == true) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notification['id'])
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        notification['is_read'] = true;
      });
    } catch (e) {
      _showMessage('Could not update notification.');
    }
  }

  Future<void> _markAllAsRead() async {
    final user = supabase.auth.currentUser;

    if (user == null || unreadCount == 0) return;

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      if (!mounted) return;

      setState(() {
        for (final item in notifications) {
          item['is_read'] = true;
        }
      });
    } catch (e) {
      _showMessage('Could not mark notifications as read.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildFilter(String filter) {
    final selected = selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5C45FD) : const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(30),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.12),
                    blurRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            if (filter == 'AI Insights') ...[
              const Icon(
                Icons.auto_awesome,
                size: 15,
                color: primary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              filter,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircleAvatar(
              radius: 29,
              backgroundColor: Color(0xFFE5EEFF),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 28,
                color: muted,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'No alerts in this category right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Something went wrong.',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _loadNotifications();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = filteredNotifications;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: primary,
                          size: 29,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TASKAI',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: null,
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Inbox',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C45FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$unreadCount new',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: unreadCount == 0 ? null : _markAllAsRead,
                          icon: const Icon(
                            Icons.done_all,
                            size: 17,
                          ),
                          label: const Text(
                            'Mark all as read',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: primary,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 43,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return _buildFilter(filters[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primary,
                            ),
                          )
                        : errorMessage != null
                            ? _buildErrorState()
                            : displayed.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _loadNotifications,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        4,
                                        20,
                                        20,
                                      ),
                                      itemCount: displayed.length,
                                      itemBuilder: (context, index) {
                                        final item = displayed[index];

                                        return NotificationCard(
                                          notification: item,
                                          onTap: () {
                                            _markAsRead(item);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
