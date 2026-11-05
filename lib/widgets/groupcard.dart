
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
    // جلب البيانات من خريطة Supabase مع قيم افتراضية للاحتياط
    final String groupName = groupData['name'] ?? 'Untitled Workspace';
    final String groupDescription = groupData['description'] ?? 'No description provided';

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
          onTap: onTap, // عند الضغط سينقلك لصفحة المجموعة
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة القروب (People دائماً) مع خلفية بنفسجية فاتحة مطابقة للهوية
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

                // تفاصيل المجموعة (الاسم والوصف)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
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
                          ),
                          const SizedBox(width: 8),
                          // زر الخيارات الجانبي (ثلاث نقاط) ديكوري
                          const Icon(
                            Icons.more_horiz,
                            color: Color(0xFF787588),
                            size: 20,
                          ),
                        ],
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
          ),
        ),
      ),
    );
  }
}