import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskmanager/widgets/search_list_card.dart';

class CreateWorkspaceDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final Future<void> Function()? onCreated;

  const CreateWorkspaceDialog({
    super.key,
    required this.supabase,
    this.onCreated,
  });

  @override
  State<CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<CreateWorkspaceDialog> {
  static const Color primaryColor = Color(0xFF5C45FD);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color subtitleColor = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color fieldColor = Color(0xFFEEF3FF);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounceTimer;

  List<SearchUser> _searchResults = [];
  final List<SearchUser> _selectedMembers = [];

  bool _isSearching = false;
  bool _isCreating = false;

  int _searchRequestId = 0;

  String? _nameError;

  @override
  void dispose() {
    _debounceTimer?.cancel();

    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // ==========================================
  // SEARCH USERS
  // ==========================================

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _searchRequestId++;

      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: 400),
      () {
        _searchUsers(query);
      },
    );
  }

  Future<void> _searchUsers(String query) async {
    final searchQuery = query.trim().replaceAll('@', '');

    if (searchQuery.isEmpty) return;

    final int requestId = ++_searchRequestId;

    setState(() {
      _isSearching = true;
    });

    try {
      final safeQuery = searchQuery
          .replaceAll(',', '')
          .replaceAll('(', '')
          .replaceAll(')', '');

      final currentUser = widget.supabase.auth.currentUser;

      final response = await widget.supabase
          .from('profiles')
          .select('id, nickname, username, avatar_path')
          .or(
            'nickname.ilike.%$safeQuery%,username.ilike.%$safeQuery%',
          )
          .limit(20);

      if (!mounted || requestId != _searchRequestId) return;

      final List<SearchUser> users = response.map<SearchUser>((user) {
        return SearchUser(
          id: user['id'].toString(),
          name: user['nickname']?.toString() ?? 'Unknown User',
          username: user['username']?.toString() ?? '',
          avatarUrl: user['avatar_path']?.toString() ?? '',
          isOnline: false,
        );
      }).where((user) {
        // Exclude the current user and already selected members.
        return user.id != currentUser?.id &&
            !_selectedMembers.any((member) => member.id == user.id);
      }).toList();

      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Workspace User Search Error: $e');

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // ==========================================
  // ADD / REMOVE MEMBERS
  // ==========================================

  void _addMember(SearchUser user) {
    if (_selectedMembers.any((member) => member.id == user.id)) {
      return;
    }

    setState(() {
      _selectedMembers.add(user);

      _searchResults.removeWhere(
        (result) => result.id == user.id,
      );

      _searchController.clear();
      _searchRequestId++;
      _isSearching = false;
    });

    _debounceTimer?.cancel();
  }

  void _removeMember(SearchUser user) {
    setState(() {
      _selectedMembers.removeWhere(
        (member) => member.id == user.id,
      );
    });
  }

  // ==========================================
  // CREATE WORKSPACE
  // ==========================================

  Future<void> _createWorkspace() async {
    final workspaceName = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (workspaceName.isEmpty) {
      setState(() {
        _nameError = 'Workspace name is required';
      });
      return;
    }

    final currentUser = widget.supabase.auth.currentUser;

    if (currentUser == null) {
      _showMessage('Please sign in first.');
      return;
    }

    setState(() {
      _isCreating = true;
      _nameError = null;
    });

    String? newGroupId;

    try {
      // 1. Create the group.
      final groupResponse = await widget.supabase
          .from('groups')
          .insert({
            'name': workspaceName,
            'description': description.isEmpty ? null : description,
            'created_by': currentUser.id,
          })
          .select('id')
          .single();

      newGroupId = groupResponse['id'].toString();

      // 2. Add the owner and selected members.
      final List<Map<String, dynamic>> members = [
        {
          'group_id': newGroupId,
          'user_id': currentUser.id,
          'role': 'owner',
        },
        ..._selectedMembers.map((user) {
          return {
            'group_id': newGroupId,
            'user_id': user.id,
            'role': 'member',
          };
        }),
      ];

      await widget.supabase.from('group_members').insert(members);

      if (!mounted) return;

      // Close the dialog after successful creation.
      final onCreated = widget.onCreated;

      Navigator.of(context).pop();

      // Refresh the workspace list.
      if (onCreated != null) {
        await onCreated();
      }
    } catch (e) {
      debugPrint('Create Workspace Error: $e');

      // Attempt to remove the group if adding members failed.
      if (newGroupId != null) {
        try {
          await widget.supabase.from('groups').delete().eq('id', newGroupId);
        } catch (rollbackError) {
          debugPrint('Workspace Rollback Error: $rollbackError');
        }
      }

      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      _showMessage('Could not create workspace. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ==========================================
  // SELECTED MEMBER TILE
  // ==========================================

  Widget _buildSelectedMember(SearchUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage:
                user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            child: user.avatarUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.username.startsWith('@')
                      ? user.username
                      : '@${user.username}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeMember(user),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close,
              color: subtitleColor,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: primaryColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Workspace',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Set up a space for your squad to build',
                          style: TextStyle(
                            fontSize: 11,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isCreating ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: subtitleColor,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // WORKSPACE NAME
              const Text(
                'Workspace Name *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _nameController,
                enabled: !_isCreating,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() {
                      _nameError = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter workspace name...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_outlined,
                    color: subtitleColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _nameError,
                ),
              ),

              const SizedBox(height: 18),

              // DESCRIPTION
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _descriptionController,
                enabled: !_isCreating,
                maxLines: 3,
                minLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'What is this workspace about?',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ADD TEAMMATES HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Teammates',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${_selectedMembers.length} Members Ready',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // SEARCH FIELD
              TextField(
                controller: _searchController,
                enabled: !_isCreating,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search users by name or username...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_search_outlined,
                    color: subtitleColor,
                    size: 20,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // SEARCH RESULTS
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 170,
                  ),
                  child: SingleChildScrollView(
                    child: SearchListCard(
                      users: _searchResults,
                      onUserTap: _addMember,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // SELECTED MEMBERS
              if (_selectedMembers.isNotEmpty) ...[
                const Text(
                  'Selected Members',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                ..._selectedMembers.map(_buildSelectedMember),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 12),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _isCreating ? null : () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5EEFF),
                          foregroundColor: textColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createWorkspace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: _isCreating
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.add_circle_outline,
                                size: 19,
                              ),
                        label: Text(
                          _isCreating ? 'Creating...' : 'Create Workspace',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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
  }
}
