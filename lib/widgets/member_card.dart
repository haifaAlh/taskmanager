import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taskmanager/widgets/task_card.dart';
import 'package:taskmanager/widgets/create_task_dialog.dart';

class MemberCard extends StatefulWidget {
  final String groupId;
  final String userId;
  final String name;
  final String username;
  final String avatarUrl;

  const MemberCard({
    super.key,
    required this.groupId,
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarUrl,
  });

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Color primaryColor = Color(0xFF5C45FD);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color outlineColor = Color(0xFFE2E8F0);

  List<Map<String, dynamic>> _tasks = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetchMemberTasks();
  }

  // ==========================================
  // FETCH MEMBER TASKS
  // ==========================================

  Future<void> _fetchMemberTasks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('group_id', widget.groupId)
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching member tasks: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ==========================================
// UPDATE TASK COMPLETION
// ==========================================

  Future<void> _updateTaskCompletion(
    Map<String, dynamic> task,
    bool isCompleted,
  ) async {
    try {
      await _supabase
          .from('tasks')
          .update({
            'status': isCompleted ? 'completed' : 'pending',
          })
          .eq('id', task['id'])
          .eq('group_id', widget.groupId)
          .eq('user_id', widget.userId);

      if (!mounted) return;

      setState(() {
        final index = _tasks.indexWhere(
          (item) => item['id'] == task['id'],
        );

        if (index != -1) {
          _tasks[index] = {
            ..._tasks[index],
            'status': isCompleted ? 'completed' : 'pending',
          };
        }
      });
    } catch (e) {
      debugPrint('Error updating task completion: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update task status.'),
        ),
      );
    }
  }

  // ==========================================
  // CREATE TASK
  // ==========================================

  Future<void> _openCreateTaskDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: CreateTaskDialog(
            groupId: widget.groupId,
            userId: widget.userId,
          ),
        );
      },
    );

    if (!mounted) return;

    // Refresh tasks after creating a task.
    if (result == true) {
      await _fetchMemberTasks();
    }
  }

  // ==========================================
  // TASK COUNTS
  // ==========================================

  int get _completedTasksCount {
    return _tasks.where((task) {
      final status = (task['status'] ?? '').toString().toLowerCase();

      return status == 'completed' || status == 'done';
    }).length;
  }

  int get _totalTasksCount => _tasks.length;

  // ==========================================
  // MEMBER AVATAR
  // ==========================================

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFEDE9FF),
      backgroundImage:
          widget.avatarUrl.isNotEmpty ? NetworkImage(widget.avatarUrl) : null,
      child: widget.avatarUrl.isEmpty
          ? const Icon(
              Icons.person,
              color: primaryColor,
              size: 25,
            )
          : null,
    );
  }

  // ==========================================
  // MEMBER HEADER
  // ==========================================

  Widget _buildHeader() {
    return Row(
      children: [
        _buildAvatar(),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.username.startsWith('@')
                    ? widget.username
                    : '@${widget.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // CREATE TASK BUTTON
        _buildHeaderButton(
          icon: Icons.add,
          backgroundColor: const Color(0xFFEDE9FF),
          iconColor: primaryColor,
          onTap: _openCreateTaskDialog,
        ),

        const SizedBox(width: 7),

        // EXPAND / COLLAPSE BUTTON
        _buildHeaderButton(
          icon:
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          backgroundColor: const Color(0xFFF1F5F9),
          iconColor: secondaryTextColor,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            color: iconColor,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TASKS HEADER
  // ==========================================

  Widget _buildTasksHeader() {
    return Row(
      children: [
        const Icon(
          Icons.checklist_rounded,
          color: primaryColor,
          size: 15,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'ASSIGNED TASKS ($_totalTasksCount)',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: primaryColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Text(
          '$_completedTasksCount Completed',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF269B70),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TASK LIST
  // ==========================================

  Widget _buildTaskList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              const Text(
                'Could not load tasks.',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              TextButton(
                onPressed: _fetchMemberTasks,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(
            'No tasks assigned yet.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _tasks.map((task) {
        final status = (task['status'] ?? 'pending').toString().toLowerCase();

        final isCompleted = status == 'completed' || status == 'done';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(
            task: task,
            isCompleted: isCompleted,
            onCompletionChanged: (value) {
              _updateTaskCompletion(task, value);
            },
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: outlineColor.withOpacity(0.5),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // MEMBER HEADER
          _buildHeader(),

          if (_isExpanded) ...[
            const SizedBox(height: 14),

            const Divider(
              height: 1,
              color: Color(0xFFEFF2FA),
            ),

            const SizedBox(height: 12),

            // TASKS HEADER
            _buildTasksHeader(),

            const SizedBox(height: 12),

            // TASKS
            _buildTaskList(),
          ],
        ],
      ),
    );
  }
}
