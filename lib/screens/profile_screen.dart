import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/rides_provider.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedPhoto;

  @override
  void initState() {
    super.initState();
    final user = context.read<RidesProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedPhoto = user?.photo ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedPhoto = base64Image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _saveProfile() {
    final provider = context.read<RidesProvider>();
    final currentUser = provider.currentUser;
    if (currentUser == null) return;

    final updatedUser = User(
      name: currentUser.name,
      email: currentUser.email,
      phone: currentUser.phone,
      gender: currentUser.gender,
      photo: _selectedPhoto,
    );
    provider.updateCurrentUser(updatedUser);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated & saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final provider = context.watch<RidesProvider>();
    final user = provider.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: Text('No active profile session.')),
      );
    }

    final offeredRides = provider.rides.where((r) => r.poster.email == user.email || r.poster.phone == user.phone).toList();
    final joinedRides = provider.rides.where((r) => r.acceptor?.email == user.email || r.acceptor?.phone == user.phone).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('My Profile & Rides', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => provider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Main Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Change Profile Picture', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 14),

                        // Profile Image Selector Header
                        Center(
                          child: Column(
                            children: [
                              UserAvatar(
                                photoUrl: _selectedPhoto,
                                name: user.name,
                                radius: 50,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library, size: 16),
                                    label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: const Text('Camera', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isEditing = false),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: primary),
                                onPressed: _saveProfile,
                                child: const Text('Save Photo'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        UserAvatar(
                          photoUrl: user.photo,
                          name: user.name,
                          radius: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(user.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
                        const SizedBox(height: 4),
                        Text('+91 ${user.phone} • ${user.email}', style: TextStyle(color: textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.gender,
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                _selectedPhoto = user.photo;
                              });
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Change Profile Picture'),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        Text('${offeredRides.length}', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 22)),
                        const SizedBox(height: 2),
                        Text('Rides Offered', style: TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        Text('${joinedRides.length}', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 22)),
                        const SizedBox(height: 2),
                        Text('Rides Joined', style: TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => provider.logout(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),

            // Footer Version
            Text(
              'AutoShare v1.0.0 Build 2026',
              style: TextStyle(color: textSecondary, fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
