import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chrome header bergaya gradient yang dipakai di semua halaman utama
/// (Beranda, Smart Bookshelf, Progress, Komunitas, Profil) supaya bentuk,
/// warna, dan radius-nya seragam. Konten di dalamnya bebas berbeda per
/// halaman (judul+ikon, judul+search bar, avatar tengah, dll) lewat [child].
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ??
          EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 20,
            20,
            24,
          ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Baris judul standar untuk dipakai di dalam [AppHeader]: judul (+subtitle
/// opsional) di kiri, satu aksi opsional di kanan (lihat [AppHeaderAction]).
class AppHeaderTitle extends StatelessWidget {
  const AppHeaderTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Kotak ikon translucent putih — dipakai untuk aksi/ikon dekoratif di atas
/// [AppHeader] (mis. ikon buku di Beranda, tombol "Tambah rak" di Bookshelf).
class AppHeaderAction extends StatelessWidget {
  const AppHeaderAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
    if (onPressed == null) return button;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: button,
      ),
    );
  }
}
