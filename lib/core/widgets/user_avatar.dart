import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.userName,
    this.radius = 18,
  });

  final String userId;
  final String userName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'P';
    
    // Tampilan awal sebelum data stream tersedia agar tidak flicker
    final fallbackAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );

    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService.watchProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallbackAvatar;

        final data = snapshot.data!;
        final photoBase64 = data['photoBase64'] as String?;
        final displayName = data['displayName'] as String? ?? userName;
        final dispInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

        if (photoBase64 != null && photoBase64.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            backgroundImage: MemoryImage(base64Decode(photoBase64)),
          );
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            dispInitial,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.8,
            ),
          ),
        );
      },
    );
  }
}
