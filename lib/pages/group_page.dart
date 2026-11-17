import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taskmanager/widgets/member_card.dart';
import 'package:taskmanager/pages/group_settings_page.dart';

class GroupPage extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const GroupPage({
    super.key,
    required this.groupData,
  });

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Color primaryColor = Color(0xFF5C45FD);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color subtitleColor = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFF8F9FF);

  List<Map<String, dynamic>> _members = [];

  int _totalTasks = 0;
  int _activeTasks = 0;
  int _completedTasks = 0;

  String? _selectedUserId;

  bool _isLoading = true;
  bool _hasError = false;

  String get _groupId => widget.groupData['id'].toString();

  String get _groupName =>
      widget.groupData['name']?.toString() ?? 'Untitled Workspace';

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  // ==========================================
  // FETCH GROUP DATA
  // ==========================================

  Future<void> _fetchGroupData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch group members and their profiles.
      final membersResponse = await _supabase
          .from('group_members')
          .select(
            'user_id, profiles!group_members_user_id_fkey'
            '(id, nickname, username, avatar_path)',
          )
          .eq('group_id', _groupId);

      // Fetch all tasks belonging to this group.
      final tasksResponse = await _supabase
          .from('tasks')
          .select('id, status')
          .eq('group_id', _groupId);

      final members = <Map<String, dynamic>>[];

      for (final row in membersResponse) {
        final profile = row['profiles'];

        if (profile == null) continue;

        members.add({
          'user_id': row['user_id'].toString(),
          'nickname': profile['nickname']?.toString() ?? 'Unknown User',
          'username': profile['username']?.toString() ?? '',
          'avatar_path': profile['avatar_path']?.toString() ?? '',
        });
      }

      final tasks = List<Map<String, dynamic>>.from(tasksResponse);

      final completedCount = tasks.where((task) {
        return (task['status'] ?? '').toString().toLowerCase() == 'completed';
      }).length;

      if (!mounted) return;

      setState(() {
        _members = members;

        _totalTasks = tasks.length;
        _completedTasks = completedCount;
        _activeTasks = _totalTasks - _completedTasks;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching group data: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // FILTER MEMBERS
  // ==========================================

  List<Map<String, dynamic>> get _filteredMembers {
    if (_selectedUserId == null) {
      return _members;
    }

    return _members.where((member) {
      return member['user_id'] == _selectedUserId;
    }).toList();
  }

  // ==========================================
  // GROUP SUMMARY
  // ==========================================

  Widget _buildGroupSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.circle,
                color: Color(0xFF047857),
                size: 12,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _groupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Settings functionality will be added later.
                },
                icon: const Icon(
                  Icons.tune_rounded,
                  color: textColor,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF4FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          if ((widget.groupData['description'] ?? '')
              .toString()
              .trim()
              .isNotEmpty) ...[
            Text(
              widget.groupData['description'].toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryBadge(
                icon: Icons.groups_rounded,
                label: '${_members.length} Members',
              ),
              _buildSummaryBadge(
                icon: Icons.checklist_rounded,
                label: '$_activeTasks Active Tasks',
              ),
            ],
          ),

          const SizedBox(height: 18),

          // TASK PROGRESS
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workspace Tasks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '$_completedTasks / $_totalTasks Completed',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _totalTasks == 0 ? 0 : _completedTasks / _totalTasks,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _totalTasks == 0
                      ? 'No tasks have been created yet.'
                      : '${((_completedTasks / _totalTasks) * 100).round()}% Complete',
                  style: const TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MEMBER FILTER
  // ==========================================

  Widget _buildMemberFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FILTERED VIEW',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: subtitleColor,
              ),
            ),
            Text(
              _selectedUserId == null ? 'All assigned' : 'Selected member',
              style: const TextStyle(
                fontSize: 11,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(
                label: 'All Members',
                selected: _selectedUserId == null,
                onTap: () {
                  setState(() {
                    _selectedUserId = null;
                  });
                },
                count: _members.length,
              ),
              const SizedBox(width: 8),
              ..._members.map((member) {
                final selected = _selectedUserId == member['user_id'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: member['nickname'],
                    selected: selected,
                    avatarUrl: member['avatar_path'],
                    onTap: () {
                      setState(() {
                        _selectedUserId = selected ? null : member['user_id'];
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? avatarUrl,
    int? count,
  }) {
    return Material(
      color: selected ? primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? primaryColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatarUrl != null) ...[
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFEDE9FF),
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 12,
                          color: primaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : textColor,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MEMBERS LIST
  // ==========================================

  Widget _buildMembersList() {
    final members = _filteredMembers;

    if (members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 35),
        child: Center(
          child: Text(
            'No members found.',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Column(
      children: members.map((member) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MemberCard(
            groupId: _groupId,
            userId: member['user_id'],
            name: member['nickname'],
            username: member['username'],
            avatarUrl: member['avatar_path'],
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // PAGE HEADER
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: const Color(0xFFF8F9FF),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.assignment_rounded,
                    color: primaryColor,
                    size: 23,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Workspace Page',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupSettingsPage(
                            supabase: _supabase,
                            groupId: _groupId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    )
                  : _hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Could not load workspace data.',
                                style: TextStyle(
                                  color: subtitleColor,
                                ),
                              ),
                              TextButton(
                                onPressed: _fetchGroupData,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchGroupData,
                          color: primaryColor,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              24,
                            ),
                            children: [
                              _buildGroupSummary(),
                              const SizedBox(height: 22),
                              _buildMemberFilter(),
                              const SizedBox(height: 20),
                              _buildMembersList(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
