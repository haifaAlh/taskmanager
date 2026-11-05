import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskmanager/pages/auth.dart'; // تأكدي من مسار الملف لديك

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _nickname;
  String? _username;
  String? _avatarPath;
  int _progressBar = 100;
  int _numOfTasks = 0;

  // قائمة صور الأفاتار المتاحة للاختيار (يمكنك استبدالها بمسارات صورك في assets)
  final List<String> _defaultAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=1',
    'https://api.dicebear.com/7.x/bottts/png?seed=2',
    'https://api.dicebear.com/7.x/bottts/png?seed=3',
    'https://api.dicebear.com/7.x/bottts/png?seed=4',
    'https://api.dicebear.com/7.x/bottts/png?seed=5',
    'https://api.dicebear.com/7.x/bottts/png?seed=6',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // جلب بيانات البروفايل مباشرة من Supabase
  Future<void> _fetchProfileData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // جلب السطر الخاص بالمستخدم من جدول profiles
      final data =
          await _supabase.from('profiles').select().eq('id', user.id).single();

      debugPrint(
          'Fetched Profile Data: $data'); // لمعاينة البيانات في الـ Console

      if (mounted) {
        setState(() {
          _nickname = data['nickname'] ?? 'User';
          _username =
              data['username'] != null ? '@${data['username']}' : '@user';
          _avatarPath = data['avatar_path'];

          // قراءة القيم مع التأكد من تحويلها إلى أرقام صحيحة وتجنب Null
          _progressBar = data['progrissbar'] != null
              ? (data['progrissbar'] as num).toInt()
              : 100;

          _numOfTasks = data['numoftasks'] != null
              ? (data['numoftasks'] as num).toInt()
              : 0;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // تحديث صورة الأفاتار المختارة في Supabase
  Future<void> _updateAvatar(String newAvatarUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      setState(() => _avatarPath = newAvatarUrl);

      await _supabase.from('profiles').update({
        'avatar_path': newAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error updating avatar: $e');
    }
  }

  // نافذة منبثقة لاختيار الصورة الشخصية (Bottom Sheet)
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _defaultAvatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final avatar = _defaultAvatars[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _updateAvatar(avatar);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatarPath == avatar
                              ? const Color(0xFF5C45FD)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(avatar),
                        backgroundColor: const Color(0xFFE5EEFF),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // حساب لون مؤشر التقدم بناءً على نسبة الـ Commitment Score
  Color _getScoreColor(int score) {
    if (score >= 70) {
      return const Color(0xFF10B981); // emerald green
    } else if (score >= 40) {
      return const Color(0xFFF59E0B); // orange/yellow
    } else {
      return const Color(0xFFBA1A1A); // red
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5C45FD);
    const surfaceBg = Color(0xFFF8F9FF);
    const textColor = Color(0xFF0B1C30);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: surfaceBg,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    final scoreColor = _getScoreColor(_progressBar);

    return Scaffold(
      backgroundColor: surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (اللوغو باليسار وعنوان الصفحة)
              Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.task_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  // أيقونة ديكورية صغيرة
                  const Icon(Icons.auto_awesome, color: primaryColor, size: 20),
                ],
              ),

              const SizedBox(height: 24),

              // Profile Card Component
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar Image with click handler
                    GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFFE5EEFF),
                              backgroundImage: _avatarPath != null
                                  ? NetworkImage(_avatarPath!)
                                  : null,
                              child: _avatarPath == null
                                  ? const Icon(Icons.person,
                                      size: 40, color: primaryColor)
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Nickname
                    Text(
                      _nickname ?? 'User Name',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Username
                    Text(
                      _username ?? '@username',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Commitment Score Card
                    // Commitment Score Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scoreColor.withOpacity(0.15)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.shield_outlined,
                                        color: scoreColor, size: 20),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Commitment Score',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scoreColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_progressBar%', // <-- هنا يعرض النسبة القادمة من المتغير
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Dynamic Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressBar /
                                  100.0, // <-- هنا يتحرك المؤشر بناءً على القيمة
                              minHeight: 8,
                              backgroundColor: Colors.black.withOpacity(0.05),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(scoreColor),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: scoreColor, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '$_progressBar% On-Time Completion', // <-- هنا النص المتغير
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: scoreColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_numOfTasks tasks', // <-- هنا يعرض عدد التاسكات القادم من المتغير
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
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

              const SizedBox(height: 24),

              // Settings Header Title
              const Text(
                'SETTINGS & WORKFLOWS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 12),

              // Settings Menu Items Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      iconBg: const Color(0xFFEDE3FF),
                      iconColor: primaryColor,
                      title: 'Account & Security',
                      subtitle: 'Passkeys, 2FA, email preferences',
                    ),
                    const Divider(
                        height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                    _buildSettingsTile(
                      icon: Icons.psychology_outlined,
                      iconBg: const Color(0xFFEDE3FF),
                      iconColor: primaryColor,
                      title: 'AI Task Preferences',
                      subtitle: 'Auto-split complexity, autonomous suggestions',
                      badgeText: 'SMART',
                    ),
                    const Divider(
                        height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                    _buildSettingsTile(
                      icon: Icons.groups_outlined,
                      iconBg: const Color(0xFFEDE3FF),
                      iconColor: primaryColor,
                      title: 'Workspaces & Team Roles',
                      subtitle: '3 active teams • Member permissions',
                    ),
                    const Divider(
                        height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_outlined,
                      iconBg: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF10B981),
                      title: 'Notification Preferences',
                      subtitle: 'Instant digests, focus hours muted',
                    ),
                    const Divider(
                        height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                    _buildSettingsTile(
                      icon: Icons.palette_outlined,
                      iconBg: const Color(0xFFE5EEFF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Appearance & Theme',
                      subtitle: 'Light Mode active',
                    ),
                    const Divider(
                        height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      iconBg: const Color(0xFFE5EEFF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Help & Support',
                      subtitle: 'Guides, AI feedback & live chat',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. تسجيل الخروج من Supabase
                    await _supabase.auth.signOut();

                    // 2. التوجيه لصفحة الدخول وحذف كل الصفحات السابقة من الـ Navigation Stack
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const AuthPage()),
                        (route) =>
                            false, // يمنع المستخدم من الرجوع للوراء بزر العودة
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDAD6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFBA1A1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // App Version Footer
              const Center(
                child: Text(
                  'Version 2.4.1 • TaskManager',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت لإنشاء عناصر القائمة المخصصة
  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Row(
        children: [
          // استخدام Expanded يمنع النص من تجاوز مساحة الشاشة وإحداث Overflow
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1C30),
              ),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5C45FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF787588),
        size: 20,
      ),
      onTap: () {},
    );
  }
}
