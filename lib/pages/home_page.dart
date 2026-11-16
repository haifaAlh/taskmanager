import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskmanager/widgets/task_card.dart';
import 'package:taskmanager/widgets/create_task_dialog.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onOpenNotifications;

  const HomePage({
    super.key,
    this.onOpenNotifications,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primary = Color(0xFF4220E5);
  static const Color primaryContainer = Color(0xFF5C45FD);
  static const Color background = Color(0xFFF8F9FF);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color muted = Color(0xFF474556);

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  String firstName = '';

  // Applied filters
  Set<int> selectedPriorities = {};
  Set<String> selectedStatuses = {};
  DateTime? selectedDeadlineDate;

  bool get hasActiveFilters {
    return selectedPriorities.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        selectedDeadlineDate != null;
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
    loadUserName();

    searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        searchQuery = searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUserName() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select('nickname')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || profile == null) return;

      final nickname = profile['nickname']?.toString().trim();

      if (nickname != null && nickname.isNotEmpty) {
        setState(() {
          firstName = nickname.split(RegExp(r'\s+')).first;
        });
      }
    } catch (e) {
      debugPrint('Could not load nickname: $e');
    }
  }

  Future<void> loadTasks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          errorMessage = 'Please sign in to view your tasks.';
          isLoading = false;
        });
        return;
      }

      final result = await supabase
          .from('tasks')
          .select(
            'id, user_id, group_id, title, description, '
            'subject_name, deadline, subject_importance, '
            'complexity, priority_level, status, '
            'created_at, updated_at',
          )
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        tasks = List<Map<String, dynamic>>.from(result);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load tasks error: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not load tasks. Please try again.';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredTasks {
    return tasks.where((task) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final title = (task['title'] ?? '').toString().toLowerCase();
        final description =
            (task['description'] ?? '').toString().toLowerCase();
        final category = (task['subject_name'] ?? '').toString().toLowerCase();

        final matchesSearch = title.contains(searchQuery) ||
            description.contains(searchQuery) ||
            category.contains(searchQuery);

        if (!matchesSearch) return false;
      }

      // Priority filter
      if (selectedPriorities.isNotEmpty) {
        final priority = int.tryParse(
          (task['priority_level'] ?? '').toString(),
        );

        if (priority == null || !selectedPriorities.contains(priority)) {
          return false;
        }
      }

      // Status filter
      if (selectedStatuses.isNotEmpty) {
        final completed = isCompleted(task['status']);
        final status = completed ? 'completed' : 'pending';

        if (!selectedStatuses.contains(status)) {
          return false;
        }
      }

      // Deadline filter
      if (selectedDeadlineDate != null) {
        final deadline = DateTime.tryParse(
          (task['deadline'] ?? '').toString(),
        );

        if (deadline == null ||
            !DateUtils.isSameDay(deadline, selectedDeadlineDate)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int get tasksDueToday {
    return tasks.where((task) {
      final date = DateTime.tryParse(
        (task['deadline'] ?? '').toString(),
      );

      if (date == null) return false;

      final now = DateTime.now();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  String formatDeadline(dynamic value) {
    if (value == null) return 'No due date';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:$minute $period';
  }

  String formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }

  String formatFilterDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool isCompleted(dynamic status) {
    final value = (status ?? '').toString().toLowerCase();

    return value == 'completed' || value == 'done';
  }

  Future<void> updateTaskStatus(
    Map<String, dynamic> task,
    bool completed,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null || task['id'] == null) return;

    try {
      final newStatus = completed ? 'completed' : 'pending';

      await supabase
          .from('tasks')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', task['id'])
          .eq('user_id', user.id);

      await loadTasks();
    } catch (e) {
      debugPrint('Update task error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update task status.'),
        ),
      );
    }
  }

  // =========================================================
  // FILTER BOTTOM SHEET
  // =========================================================

  Future<void> _showFilterSheet() async {
    Set<int> draftPriorities = Set.from(selectedPriorities);
    Set<String> draftStatuses = Set.from(selectedStatuses);
    DateTime? draftDeadline = selectedDeadlineDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget buildOption({
              required String label,
              required bool selected,
              required Color color,
              required VoidCallback onTap,
            }) {
              return GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.12)
                        : const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : const Color(0xFFE8EAF2),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        Icon(Icons.check_circle, color: color, size: 16),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? color : textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget sectionTitle(String title, IconData icon) {
              return Row(
                children: [
                  Icon(icon, color: primary, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Header
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filter Tasks',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: muted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Priority
                      sectionTitle(
                        'Priority',
                        Icons.flag_outlined,
                      ),
                      const SizedBox(height: 13),

                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          buildOption(
                            label: 'High',
                            selected: draftPriorities.contains(1),
                            color: const Color(0xFFE5484D),
                            onTap: () {
                              setSheetState(() {
                                if (!draftPriorities.add(1)) {
                                  draftPriorities.remove(1);
                                }
                              });
                            },
                          ),
                          buildOption(
                            label: 'Medium',
                            selected: draftPriorities.contains(2),
                            color: const Color(0xFFE89A27),
                            onTap: () {
                              setSheetState(() {
                                if (!draftPriorities.add(2)) {
                                  draftPriorities.remove(2);
                                }
                              });
                            },
                          ),
                          buildOption(
                            label: 'Low',
                            selected: draftPriorities.contains(3),
                            color: const Color(0xFF15966A),
                            onTap: () {
                              setSheetState(() {
                                if (!draftPriorities.add(3)) {
                                  draftPriorities.remove(3);
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Status
                      sectionTitle(
                        'Status',
                        Icons.task_alt_outlined,
                      ),
                      const SizedBox(height: 13),

                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          buildOption(
                            label: 'Pending',
                            selected: draftStatuses.contains('pending'),
                            color: const Color(0xFF3976D3),
                            onTap: () {
                              setSheetState(() {
                                if (!draftStatuses.add('pending')) {
                                  draftStatuses.remove('pending');
                                }
                              });
                            },
                          ),
                          buildOption(
                            label: 'Completed',
                            selected: draftStatuses.contains('completed'),
                            color: const Color(0xFF15966A),
                            onTap: () {
                              setSheetState(() {
                                if (!draftStatuses.add('completed')) {
                                  draftStatuses.remove('completed');
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Deadline
                      sectionTitle(
                        'Deadline',
                        Icons.calendar_month_outlined,
                      ),
                      const SizedBox(height: 13),

                      GestureDetector(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: draftDeadline ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primary,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: textColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedDate != null) {
                            setSheetState(() {
                              draftDeadline = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                              );
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: const Color(0xFFE8EAF2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: primary,
                                size: 19,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  draftDeadline == null
                                      ? 'Select deadline'
                                      : formatFilterDate(draftDeadline!),
                                  style: TextStyle(
                                    color: draftDeadline == null
                                        ? muted
                                        : textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (draftDeadline != null)
                                IconButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      draftDeadline = null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: muted,
                                    size: 19,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              else
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: muted,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  selectedPriorities.clear();
                                  selectedStatuses.clear();
                                  selectedDeadlineDate = null;
                                });

                                Navigator.pop(sheetContext);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: const BorderSide(color: primary),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedPriorities =
                                      Set.from(draftPriorities);
                                  selectedStatuses = Set.from(draftStatuses);
                                  selectedDeadlineDate = draftDeadline;
                                });

                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryContainer,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: const Text(
                                'Apply Filters',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryContainer,
        foregroundColor: Colors.white,
        onPressed: () async {
          final created = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateTaskDialog(),
          );

          if (created == true && mounted) {
            await loadTasks();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task created successfully!'),
              ),
            );
          }
        },
        child: const Icon(Icons.add, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadTasks,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildGreeting(now),
                    const SizedBox(height: 22),
                    _buildDigest(),
                    const SizedBox(height: 22),
                    _buildSearch(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(),
                    const SizedBox(height: 13),
                    _buildTaskContent(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/logo.png',
          width: 39,
          height: 39,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        const Column(
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
              'Home Tasks',
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.auto_awesome,
            color: primaryContainer,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(DateTime now) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty ? 'Hello 👋' : 'Hello, $firstName 👋',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006C49),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${formatDate(now)} • '
                      '$tasksDueToday tasks due today',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            widget.onOpenNotifications?.call();
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: textColor,
            size: 27,
          ),
        ),
      ],
    );
  }

  Widget _buildDigest() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.auto_awesome,
                color: primaryContainer,
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'AI DAILY DIGEST',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isLoading
                ? 'Loading your productivity information...'
                : 'You have ${tasks.length} tasks in your list.',
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEFF4FF)),
          const Row(
            children: [
              Icon(Icons.insights, color: primary, size: 19),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Focus Score',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '--',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 49,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search tasks, subtasks, tags...',
                hintStyle: TextStyle(
                  color: Color(0xFF787588),
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF787588),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 49,
          width: 49,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: hasActiveFilters
                ? Border.all(color: primary, width: 1.4)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: IconButton(
                  onPressed: _showFilterSheet,
                  icon: const Icon(
                    Icons.tune,
                    color: muted,
                  ),
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        const Text(
          "Today's Focus",
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          hasActiveFilters
              ? '${filteredTasks.length} results'
              : 'Sorted by Smart Priority',
          style: const TextStyle(
            color: Color(0xFF787588),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(35),
        child: Center(
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }

    if (errorMessage != null) {
      return _buildMessage(
        Icons.error_outline,
        'Unable to load tasks',
        errorMessage!,
        action: TextButton(
          onPressed: loadTasks,
          child: const Text('Try Again'),
        ),
      );
    }

    final visibleTasks = filteredTasks;

    if (visibleTasks.isEmpty) {
      return _buildMessage(
        Icons.filter_list_off,
        'No Tasks Found',
        searchQuery.isNotEmpty || hasActiveFilters
            ? 'No tasks match your search or selected filters.'
            : 'No tasks found in your account yet.',
      );
    }

    return Column(
      children: visibleTasks.map((task) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTaskCard(task),
        );
      }).toList(),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final completed = isCompleted(task['status']);

    return TaskCard(
      task: task,
      isCompleted: completed,
      onCompletionChanged: (value) {
        updateTaskStatus(task, value);
      },
    );
  }

  Widget _buildMessage(
    IconData icon,
    String title,
    String message, {
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryContainer, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
