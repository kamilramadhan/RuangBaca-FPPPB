import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'app_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser>(
      stream: AuthService.instance.userChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? AuthService.instance.currentUser;
        return _ProfileView(user: user);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService.watchProfile(user.uid),
      builder: (context, snap) {
        final profileData = snap.data ?? {};
        final displayName = profileData['displayName'] as String? ?? user.displayName;
        final photoBase64 = profileData['photoBase64'] as String?;

        return Scaffold(
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 20, 20, 30),
                child: Column(children: [
                  const AppHeaderTitle(title: 'Profil Saya'),
                  const SizedBox(height: 20),

                  // Avatar / Photo dari Firestore (realtime)
                  GestureDetector(
                    onTap: () => _openEditProfile(context, photoBase64, displayName),
                    child: Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: photoBase64 != null && photoBase64.isNotEmpty
                              ? MemoryImage(base64Decode(photoBase64))
                              : null,
                          child: photoBase64 == null || photoBase64.isEmpty
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: AppTheme.primaryColor),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email.isNotEmpty ? user.email : 'Mode lokal',
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Pengaturan',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(children: [
                    ListTile(
                      leading:
                          const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                      title: const Text('Edit Profil'),
                      subtitle: const Text('Ganti nama & foto profil'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openEditProfile(context, photoBase64, displayName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Tentang Aplikasi'),
                      subtitle: const Text('RuangBaca v1.0.0'),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXl)),
                          title: const Row(children: [
                            Icon(Icons.auto_stories_rounded,
                                color: AppTheme.primaryColor),
                            SizedBox(width: 10),
                            Text('RuangBaca'),
                          ]),
                          content: const Text(
                              'Aplikasi mobile perpustakaan digital untuk membantu pengguna menemukan, mengelola, dan mendiskusikan buku secara lebih interaktif guna meningkatkan minat baca dan literasi digital masyarakat.\n\nSDG\'s 4 — Quality Education'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Tutup')),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Keluar',
                          style: TextStyle(color: Colors.red)),
                      onTap: () => _confirmLogout(context),
                    ),
                  ]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ]),
        );
      },
    );
  }

  void _openEditProfile(
      BuildContext context, String? currentPhotoBase64, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl))),
      builder: (_) => _EditProfileSheet(
        uid: user.uid,
        currentName: currentName,
        currentPhotoBase64: currentPhotoBase64,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: const Text('Keluar?'),
        content: const Text('Kamu perlu masuk lagi untuk mengakses akunmu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}

// ── Bottom sheet untuk edit profil ──
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.uid,
    required this.currentName,
    required this.currentPhotoBase64,
  });
  final String uid;
  final String currentName;
  final String? currentPhotoBase64;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  String? _photoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _photoBase64 = widget.currentPhotoBase64;
    _nameCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      // Pick image, limit size and compress to keep base64 string lightweight
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_photoBase64 != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _photoBase64 = ''; // Empty string represents removal of photo
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ProfileService.updateProfile(
        uid: widget.uid,
        displayName: _nameCtrl.text.trim(),
        photoBase64: _photoBase64,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),

        Text('Edit Profil',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),

        // Preview avatar / photo
        GestureDetector(
          onTap: _showImageSourcePicker,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: _photoBase64 != null && _photoBase64!.isNotEmpty
                      ? MemoryImage(base64Decode(_photoBase64!))
                      : null,
                  child: _photoBase64 == null || _photoBase64!.isEmpty
                      ? Text(
                          _nameCtrl.text.isNotEmpty
                              ? _nameCtrl.text[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                        )
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ketuk untuk ganti foto',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 25),

        // Nama
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Tampilan',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded),
            label: const Text('Simpan'),
          ),
        ),
      ]),
    );
  }
}
