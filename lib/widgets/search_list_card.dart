import 'package:flutter/material.dart';

class SearchUser {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final bool isOnline;

  const SearchUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    this.isOnline = false,
  });
}

class SearchListCard extends StatelessWidget {
  final List<SearchUser> users;
  final ValueChanged<SearchUser>? onUserTap;

  const SearchListCard({
    super.key,
    required this.users,
    this.onUserTap,
  });

  static const Color textColor = Color(0xFF0B1C30);
  static const Color subtitleColor = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color primaryColor = Color(0xFF5C45FD);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(users.length, (index) {
            final user = users[index];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildUserTile(user),
                if (index != users.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                    indent: 0,
                    endIndent: 0,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildUserTile(SearchUser user) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onUserTap?.call(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          child: Row(
            children: [
              // User Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: const Color(0xFFEDE9FE),
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: primaryColor,
                          )
                        : null,
                  ),

                  // Online Indicator
                  if (user.isOnline)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Name and Username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.username.startsWith('@')
                          ? user.username
                          : '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
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
