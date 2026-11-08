import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String? nickname;
  final String? username;
  final String? avatarPath;
  final int progressBar;
  final int numOfTasks;
  final VoidCallback? onAvatarTap;

  const ProfileCard({
    super.key,
    required this.nickname,
    required this.username,
    required this.avatarPath,
    required this.progressBar,
    required this.numOfTasks,
    this.onAvatarTap,
  });

  Color _getScoreColor(int score) {
    if (score >= 70) {
      return const Color(0xFF10B981);
    } else if (score >= 40) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFFBA1A1A);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5C45FD);
    const textColor = Color(0xFF0B1C30);

    final scoreColor = _getScoreColor(progressBar);

    return Container(
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
          // Avatar Image
          GestureDetector(
            onTap: onAvatarTap,
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
                    backgroundImage:
                        avatarPath != null && avatarPath!.isNotEmpty
                            ? NetworkImage(avatarPath!)
                            : null,
                    child: avatarPath == null || avatarPath!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: primaryColor,
                          )
                        : null,
                  ),
                ),

                // Edit Icon (يظهر فقط إذا كانت البطاقة قابلة للتعديل)
                if (onAvatarTap != null)
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
            nickname ?? 'User Name',
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
            username ?? '@username',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Commitment Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scoreColor.withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: scoreColor,
                            size: 20,
                          ),
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$progressBar%',
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

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressBar.clamp(0, 100) / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: scoreColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$progressBar% On-Time Completion',
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
                      '$numOfTasks tasks',
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
    );
  }
}
