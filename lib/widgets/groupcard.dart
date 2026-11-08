import 'package:flutter/material.dart';

class GroupCard extends StatelessWidget {
  final Map<String, dynamic> groupData;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.groupData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String groupName = groupData['name'] ?? 'Untitled Workspace';
    final String groupDescription =
        groupData['description'] ?? 'No description provided';

    final String createdAt = groupData['created_at'] != null
        ? groupData['created_at'].toString().substring(0, 10)
        : 'Recently';

    // استخراج قائمة الأعضاء بطريقة آمنة تماماً
    final List<dynamic> members = groupData['group_members'] ?? [];

    List<String> avatarUrls = [];
    for (var member in members) {
      if (member is Map<String, dynamic>) {
        final profile = member['profiles'];
        if (profile is Map<String, dynamic>) {
          final String path = profile['avatar_path'] ?? '';
          if (path.isNotEmpty) {
            avatarUrls.add(path);
          }
        }
      }
    }

    final int displayCount = avatarUrls.length > 3 ? 3 : avatarUrls.length;

    final double avatarsWidth = avatarUrls.isEmpty
        ? 0
        : avatarUrls.length > 3
            ? 90
            : 30 + (displayCount - 1) * 20;

    const primaryColor = Color(0xFF5C45FD);
    const textColor = Color(0xFF0B1C30);
    const subtitleColor = Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.03),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        color: primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            groupDescription,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: subtitleColor,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),

                // شارة Active Group بلون أخضر فاتح وحواف أغمق

                const SizedBox(height: 14),

                // صور الأعضاء الحقيقية وتاريخ الإنشاء
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: avatarsWidth,
                      height: 30,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: _buildAvatarsStack(avatarUrls),
                      ),
                    ),
                    Text(
                      'Created: $createdAt',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء الأيقونات المتداخلة للأعضاء
  // دالة مساعدة لبناء الأيقونات المتداخلة للأعضاء
  List<Widget> _buildAvatarsStack(List<String> urls) {
    List<Widget> widgets = [];
    int displayCount = urls.length > 3 ? 3 : urls.length;

    for (int i = 0; i < displayCount; i++) {
      widgets.add(
        Positioned(
          left: (i * 20).toDouble(),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: urls[i].isNotEmpty
                    ? NetworkImage(urls[i])
                    : const NetworkImage('https://i.pravatar.cc/150?img=1')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }

    if (urls.length > 3) {
      int remaining = urls.length - 3;
      widgets.add(
        Positioned(
          left: 60,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE3FF),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white,
                  width: 2), // تم تصحيحها هنا بإضافة Border.
            ),
            child: Center(
              child: Text(
                '+$remaining',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C45FD),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}
