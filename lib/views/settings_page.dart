import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _auth = AuthService();

  String? _displayName;
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final data = await _auth.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _displayName = data?.displayName ?? '';
          _photoUrl = data?.photoUrl;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  Future<void> _showEditProfile() async {
    final nameController = TextEditingController(text: _displayName);
    final photoController = TextEditingController(text: _photoUrl);

    bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: photoController,
              decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPhoto = photoController.text.trim().isEmpty ? null : photoController.text.trim();
              final res = await _auth.updateProfile(displayName: newName, photoUrl: newPhoto);
              if (res == null) {
                if (mounted) {
                  setState(() {
                    _displayName = newName;
                    _photoUrl = newPhoto;
                  });
                }
                Navigator.pop(context, true);
              } else {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      // optionally do something after save
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppConstants.appBarColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                          ? NetworkImage(_photoUrl!) as ImageProvider
                          : null,
                      child: (_photoUrl == null || _photoUrl!.isEmpty) ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName ?? 'Unknown',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _auth.currentUser?.email ?? '',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _showEditProfile,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

             

                // Dark mode toggle using ThemeProvider
                Consumer<ThemeProvider>(
                  builder: (context, theme, child) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark mode'),
                      secondary: const Icon(Icons.dark_mode),
                      value: theme.isDarkMode,
                      onChanged: (val) => theme.setTheme(val),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Other settings placeholder
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App version'),
                  subtitle: const Text('1.0.0'),
                ),
              ],
            ),
    );
  }
}