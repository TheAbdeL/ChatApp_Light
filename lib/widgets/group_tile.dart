import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../utils/constants.dart';

/// Widget pour afficher une tuile de groupe dans la liste
class GroupTile extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupTile({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(26),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppConstants.primaryColor,
          backgroundImage: (group.groupPhoto != null && group.groupPhoto!.isNotEmpty)
              ? NetworkImage(group.groupPhoto!)
              : null,
          child: (group.groupPhoto == null || group.groupPhoto!.isEmpty)
              ? const Icon(Icons.group, color: Colors.white, size: 28)
              : null,
        ),
        title: Text(
          group.groupName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF2D2D2D),
          ),
        ),
        subtitle: Text(
          '${group.members.length} membres',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: AppConstants.primaryColor,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}