import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupSettingsPage extends StatefulWidget {
  final SupabaseClient supabase;
  final String groupId;

  const GroupSettingsPage({
    super.key,
    required this.supabase,
    required this.groupId,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  // Colors
  static const Color primary = Color(0xFF5C45FD);
  static const Color background = Color(0xFFF8F9FF);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color secondaryText = Color(0xFF474556);
  static const Color fieldColor = Color(0xFFEFF4FF);
  static const Color errorColor = Color(0xFFBA1A1A);

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _members = [];

  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;

  String? get _currentUserId => widget.supabase.auth.currentUser?.id;

  bool get _isOwner =>
      _currentUserId != null && _group?['created_by'] == _currentUserId;

  // Text styles
  TextStyle get headingStyle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  TextStyle get sectionStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      );

  TextStyle get bodyStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      );

  TextStyle get labelStyle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondaryText,
      );

  TextStyle get smallStyle => const TextStyle(
        fontSize: 12,
        color: secondaryText,
      );

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // LOAD WORKSPACE
  Future<void> _loadGroup() async {
    setState(() => _loading = true);

    try {
      final group = await widget.supabase
          .from('groups')
          .select('id, name, description, icon, created_by')
          .eq('id', widget.groupId)
          .single();

      final members = await widget.supabase
          .from('group_members')
          .select(
            'user_id, role, profiles!group_members_user_id_fkey'
            '(nickname, username, email, avatar_path)',
          )
          .eq('group_id', widget.groupId);

      if (!mounted) return;

      setState(() {
        _group = group;
        _nameController.text = group['name']?.toString() ?? '';

        _descriptionController.text = group['description']?.toString() ?? '';

        _members = List<Map<String, dynamic>>.from(members);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load Group Error: $e');

      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Could not load workspace details.');
    }
  }

  // SAVE WORKSPACE
  Future<void> _saveChanges() async {
    if (!_isOwner) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage('Workspace name is required.');
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.supabase.from('groups').update({
        'name': name,
        'description': description.isEmpty ? null : description,
      }).eq('id', widget.groupId);

      if (!mounted) return;

      setState(() {
        _group!['name'] = name;
        _group!['description'] = description;
        _saving = false;
      });

      _showMessage('Settings updated successfully.');
    } catch (e) {
      debugPrint('Save Group Error: $e');

      if (!mounted) return;

      setState(() => _saving = false);
      _showMessage('Could not update workspace.');
    }
  }

  // DELETE CONFIRMATION
  Future<void> _confirmDelete() async {
    if (!_isOwner) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Workspace?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this workspace and its related data? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: secondaryText),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteWorkspace();
    }
  }

  // DELETE WORKSPACE
  Future<void> _deleteWorkspace() async {
    setState(() => _deleting = true);

    try {
      // Replace the function name and parameter
      // with the exact RPC details provided by Backend.
      await widget.supabase.rpc(
        'delete_workspace',
        params: {
          'p_group_id': widget.groupId,
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Delete Workspace Error: $e');

      if (!mounted) return;

      setState(() => _deleting = false);
      _showMessage('Could not delete workspace.');
    }
  }

  // SNACKBAR
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF213145),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  // SECTION HEADER
  Widget _sectionHeader(
    String title, {
    String? subtitle,
    String? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: sectionStyle),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle, style: smallStyle),
              ],
            ],
          ),
        ),
        if (trailing != null) Text(trailing, style: smallStyle),
      ],
    );
  }

  // TEXT FIELD
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isOwner && !_saving && !_deleting,
          maxLines: maxLines,
          maxLength: maxLines > 1 ? 200 : null,
          style: bodyStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: smallStyle,
            filled: true,
            fillColor: fieldColor,
            contentPadding: const EdgeInsets.all(12),
            counterStyle: smallStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: primary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // WORKSPACE DETAILS
  Widget _buildWorkspaceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFFE8E4FF),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WORKSPACE NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      enabled: _isOwner && !_saving && !_deleting,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Workspace name',
                        hintStyle: smallStyle,
                        filled: true,
                        fillColor: fieldColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildField(
            label: 'Description',
            controller: _descriptionController,
            hint: 'What is this workspace about?',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // MEMBER ITEM
  Widget _buildMember(Map<String, dynamic> member) {
    final profile = member['profiles'] is Map
        ? Map<String, dynamic>.from(member['profiles'])
        : <String, dynamic>{};

    final nickname = profile['nickname']?.toString() ?? '';
    final username = profile['username']?.toString() ?? '';
    final email = profile['email']?.toString() ?? '';
    final avatar = profile['avatar_path']?.toString() ?? '';
    final role = member['role']?.toString() ?? 'member';

    final displayName = nickname.trim().isNotEmpty
        ? nickname
        : username.isNotEmpty
            ? username
            : 'Unknown User';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 9,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: fieldColor,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? const Icon(
                    Icons.person_outline,
                    color: primary,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isNotEmpty
                      ? email
                      : username.isNotEmpty
                          ? (username.startsWith('@') ? username : '@$username')
                          : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: smallStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: role.toLowerCase() == 'owner'
                  ? const Color(0xFFE4DFFF)
                  : fieldColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: role.toLowerCase() == 'owner'
                    ? const Color(0xFF150067)
                    : secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MEMBERS CARD
  Widget _buildMembersCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _members.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No members found.',
                  style: smallStyle,
                ),
              ),
            )
          : Column(
              children: _members.map(_buildMember).toList(),
            ),
    );
  }

  // DANGER ZONE
  Widget _buildDangerZone() {
    if (!_isOwner) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: errorColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: sectionStyle.copyWith(
                  color: errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delete Entire Workspace',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: errorColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Permanently delete the workspace and its related data.',
                        style: smallStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _deleting ? null : _confirmDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MAIN PAGE
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving && !_deleting,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: primary,
                  ),
                )
              : _group == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Workspace not found.',
                            style: bodyStyle,
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Go Back',
                              style: TextStyle(color: primary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // HEADER
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: background,
                            border: Border(
                              bottom: BorderSide(
                                color: fieldColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _saving || _deleting
                                    ? null
                                    : () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  size: 24,
                                ),
                                color: textColor,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Workspace Settings',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      _nameController.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: smallStyle,
                                    ),
                                  ],
                                ),
                              ),
                              if (_isOwner)
                                TextButton(
                                  onPressed: _saving || _deleting
                                      ? null
                                      : _saveChanges,
                                  child: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: primary,
                                          ),
                                        )
                                      : const Text(
                                          'Save',
                                          style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                )
                              else
                                const SizedBox(width: 48),
                            ],
                          ),
                        ),

                        // CONTENT
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              20,
                              16,
                              32,
                            ),
                            children: [
                              _sectionHeader('Workspace Details'),
                              const SizedBox(height: 14),
                              _buildWorkspaceCard(),
                              const SizedBox(height: 24),
                              _sectionHeader(
                                'Members',
                                subtitle:
                                    'Active contributors in this workspace',
                                trailing: '${_members.length} Members',
                              ),
                              const SizedBox(height: 12),
                              _buildMembersCard(),
                              if (_isOwner) ...[
                                const SizedBox(height: 24),
                                _buildDangerZone(),
                              ],
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
