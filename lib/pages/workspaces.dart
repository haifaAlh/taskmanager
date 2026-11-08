import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taskmanager/widgets/groupcard.dart' show GroupCard;
import 'package:taskmanager/widgets/search_list_card.dart';
import 'package:taskmanager/widgets/profilecard.dart';
import 'package:taskmanager/widgets/create_workspace_dialog.dart';

class WorkspacesPage extends StatefulWidget {
  const WorkspacesPage({super.key});

  @override
  State<WorkspacesPage> createState() => _WorkspacesPageState();
}

class _WorkspacesPageState extends State<WorkspacesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _searchController = TextEditingController();

  // Search debounce
  Timer? _searchDebounce;

  // Prevent old search requests from replacing newer results
  int _searchRequestId = 0;

  // Colors
  static const Color primaryColor = Color(0xFF5C45FD);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color outlineColor = Color(0xFFE2E8F0);

  // Workspace states
  bool _isLoading = true;
  bool _hasError = false;

  List<Map<String, dynamic>> _userGroups = [];

  // User search states
  bool _isSearchingUsers = false;
  String? _searchError;

  List<SearchUser> _searchResults = [];

  @override
  void initState() {
    super.initState();

    _fetchUserWorkspaces();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // FETCH USER WORKSPACES
  // =========================================================

  Future<void> _fetchUserWorkspaces() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _userGroups = [];
          _isLoading = false;
        });

        return;
      }

      // Get groups belonging to the current user
      final memberRows = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', user.id);

      final List<String> groupIds =
          memberRows.map<String>((row) => row['group_id'].toString()).toList();

      if (groupIds.isEmpty) {
        if (!mounted) return;

        setState(() {
          _userGroups = [];
          _isLoading = false;
        });

        return;
      }

      // Fetch groups and their members
      final groupsData = await _supabase
          .from('groups')
          .select(
            'id, name, description, created_at, '
            'group_members(user_id, profiles!group_members_user_id_fkey(avatar_path))',
          )
          .inFilter('id', groupIds);

      debugPrint('GROUP IDS: $groupIds');
      debugPrint('GROUPS DATA: $groupsData');
      debugPrint('GROUPS COUNT: ${groupsData.length}');

      if (!mounted) return;

      setState(() {
        _userGroups = groupsData
            .map<Map<String, dynamic>>(
              (group) => Map<String, dynamic>.from(group),
            )
            .toList();

        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Workspace Error: $error');
      debugPrint('Workspace StackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // SEARCH USERS
  // =========================================================

  void _onSearchChanged(String query) {
    // Cancel previous debounce
    _searchDebounce?.cancel();

    // Rebuild the search field and its border
    if (mounted) {
      setState(() {});
    }

    // Empty search: return to workspace list
    if (query.trim().isEmpty) {
      _searchRequestId++;

      setState(() {
        _searchResults = [];
        _isSearchingUsers = false;
        _searchError = null;
      });

      return;
    }

    // Wait until the user stops typing
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        _searchUsers(query);
      },
    );
  }

  Future<void> _searchUsers(String query) async {
    final searchQuery = query.trim().replaceAll('@', '');

    if (searchQuery.isEmpty) return;

    // Give this request a unique ID
    final int requestId = ++_searchRequestId;

    if (!mounted) return;

    setState(() {
      _isSearchingUsers = true;
      _searchError = null;
    });

    try {
      // Prevent special PostgREST filter characters
      final safeQuery = searchQuery
          .replaceAll(',', '')
          .replaceAll('(', '')
          .replaceAll(')', '');

      // Search all profiles by nickname or username
      final response = await _supabase
          .from('profiles')
          .select('id, nickname, username, avatar_path')
          .or(
            'nickname.ilike.%$safeQuery%,username.ilike.%$safeQuery%',
          )
          .limit(20);

      // Ignore outdated requests
      if (!mounted || requestId != _searchRequestId) return;

      final List<SearchUser> users = response.map<SearchUser>((user) {
        return SearchUser(
          id: user['id'].toString(),
          name: user['nickname']?.toString() ?? 'Unknown User',
          username: user['username']?.toString() ?? '',
          avatarUrl: user['avatar_path']?.toString() ?? '',
          isOnline: false,
        );
      }).toList();

      debugPrint('USER SEARCH QUERY: $searchQuery');
      debugPrint('USER SEARCH RESULTS: ${users.length}');

      setState(() {
        _searchResults = users;
        _isSearchingUsers = false;
        _searchError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('User Search Error: $error');
      debugPrint('User Search StackTrace: $stackTrace');

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searchResults = [];
        _isSearchingUsers = false;
        _searchError = 'Something went wrong';
      });
    }
  }

  //==========================================================
  // SHOW USER PROFILE
  // =========================================================

  Future<void> _showUserProfile(SearchUser user) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select(
            'nickname, username, avatar_path, progrissbar, numoftasks',
          )
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      final progress = (response['progrissbar'] as num?)?.toInt() ?? 100;
      final tasks = (response['numoftasks'] as num?)?.toInt() ?? 0;

      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: const Color(0xFFF8F9FF),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  ProfileCard(
                    nickname: response['nickname']?.toString() ?? 'User',
                    username: response['username'] != null
                        ? '@${response['username']}'
                        : '@user',
                    avatarPath: response['avatar_path']?.toString(),
                    progressBar: progress,
                    numOfTasks: tasks,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error loading user profile: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load user profile.'),
        ),
      );
    }
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.task_alt,
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Workspaces',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1EEFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: primaryColor,
            size: 21,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SEARCH FIELD
  // =========================================================

  Widget _buildSearchField() {
    final bool hasQuery = _searchController.text.isNotEmpty;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasQuery ? primaryColor : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          color: textColor,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 19,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: primaryColor,
            size: 21,
          ),
          hintText: 'Search people...',
          hintStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: secondaryTextColor,
            fontSize: 13,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(
                    Icons.close,
                    color: secondaryTextColor,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle() {
    final bool searching = _searchController.text.trim().isNotEmpty;

    return Text(
      searching ? 'Search Results' : 'Your Workspaces',
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState({
    required bool searching,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E4FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              searching
                  ? Icons.person_search_outlined
                  : Icons.folder_open_outlined,
              color: primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            searching ? 'No users found' : 'No workspaces found',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searching
                ? 'Try another name or username.'
                : 'Create your first workspace to get started.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: secondaryTextColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchUserWorkspaces,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // WORKSPACE LIST
  // =========================================================

  Widget _buildWorkspaceList() {
    if (_userGroups.isEmpty) {
      return _buildEmptyState(searching: false);
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchUserWorkspaces,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 16,
        ),
        itemCount: _userGroups.length,
        itemBuilder: (context, index) {
          return GroupCard(
            groupData: _userGroups[index],
            onTap: () {
              // Navigate to workspace details.
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // USER SEARCH RESULTS
  // =========================================================

  Widget _buildUserSearchResults() {
    if (_isSearchingUsers) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: secondaryTextColor,
            ),
            const SizedBox(height: 12),
            Text(
              _searchError!,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchUsers(_searchController.text);
              },
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(searching: true);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 16,
      ),
      child: SearchListCard(
        users: _searchResults,
        onUserTap: (user) {
          _showUserProfile(user);
        },
      ),
    );
  }

  // =========================================================
  // NEW WORKSPACE BUTTON
  // =========================================================

  Widget _buildNewWorkspaceButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return CreateWorkspaceDialog(
                supabase: _supabase,
                onCreated: _fetchUserWorkspaces,
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: primaryColor.withOpacity(0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(
          Icons.add,
          size: 21,
        ),
        label: const Text(
          'New Workspace',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final bool searching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth < 640
                ? 20
                : constraints.maxWidth < 1024
                    ? 24
                    : 32;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 20,
                          bottom: 24,
                        ),
                        child: _buildHeader(),
                      ),

                      // Search
                      _buildSearchField(),

                      const SizedBox(height: 24),

                      // Section title
                      _buildSectionTitle(),

                      const SizedBox(height: 12),

                      // Main content
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              )
                            : _hasError
                                ? _buildErrorState()
                                : searching
                                    ? _buildUserSearchResults()
                                    : _buildWorkspaceList(),
                      ),

                      // New workspace button
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          bottom: 20,
                        ),
                        child: _buildNewWorkspaceButton(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
