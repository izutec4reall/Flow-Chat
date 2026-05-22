import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/media_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final String? heroTag;

  const UserProfileScreen({
    super.key, 
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: UserService().getUserStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final user = snapshot.data;
          if (user == null) return Center(child: Text(context.t('userNotFoundError')));

          final bool isCurrentUser = userId == AuthService().currentUser?.uid;

          return CustomScrollView(
            slivers: [
              // Stylish Header with Image
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Photo
                      user.coverUrl != null
                          ? Image.network(user.coverUrl!, fit: BoxFit.cover)
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withAlpha(150),
                                    Theme.of(context).colorScheme.secondary.withAlpha(150),
                                  ],
                                ),
                              ),
                              child: Icon(Icons.wallpaper, size: 64, color: Colors.white.withAlpha(50)),
                            ),
                      // Dark overlay for bottom text readability
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                      // Circular Profile Picture
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Hero(
                          tag: heroTag ?? 'avatar_$userId',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundImage: (photoUrl != null || user.photoUrl != null)
                                  ? NetworkImage(photoUrl ?? user.photoUrl!)
                                  : null,
                              child: (photoUrl == null && user.photoUrl == null)
                                  ? Text(
                                      (displayName ?? user.displayName).substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 40, 
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      // Edit Cover Button
                      if (isCurrentUser)
                        Positioned(
                          top: 40,
                          right: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.black45,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: () => _updatePhoto(context, isCover: true),
                            ),
                          ),
                        ),
                      // Edit Profile Button
                      if (isCurrentUser)
                        Positioned(
                          bottom: 20,
                          left: 95,
                          child: GestureDetector(
                            onTap: () => _updatePhoto(context, isCover: false),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.edit, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        displayName ?? user.displayName,
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildRoleBadge(context, user.role),
                                    ],
                                  ),
                                  if (user.username != null)
                                    Text(
                                      '@${user.username}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: user.isOnline 
                                    ? Colors.green.withAlpha(30) 
                                    : Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: user.isOnline ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    user.isOnline ? context.t('online') : context.t('offline'),
                                    style: TextStyle(
                                      color: user.isOnline ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Bio Section
                        _buildInfoSection(
                          context,
                          context.t('about'),
                          user.bio ?? context.t('noBio'),
                          Icons.info_outline,
                        ),
                        
                        const Divider(height: 40),
                        
                        // Media & Files (Placeholders)
                        Text(
                          context.t('mediaLinksDocs'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) => Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurface.withAlpha(50)),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: Text(context.t('sendMessage')),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildCircleAction(context, Icons.call, context.t('call')),
                            _buildCircleAction(context, Icons.videocam, context.t('video')),
                            _buildCircleAction(context, Icons.share, context.t('share')),
                            _buildCircleAction(context, Icons.block, context.t('block'), isError: true, onTap: () => _blockUser(context, userId, displayName ?? user.displayName)),
                          ],
                        ),

                        // Admin Controls Section
                        FutureBuilder<UserModel?>(
                          future: UserService().getUser(AuthService().currentUser?.uid ?? ''),
                          builder: (context, currentSnapshot) {
                            final currentUser = currentSnapshot.data;
                            final canManage = currentUser?.role == 'admin' || currentUser?.role == 'developer';
                            
                            if (!canManage) return const SizedBox.shrink();
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 40),
                                Text(
                                  context.t('adminControls'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListTile(
                                  leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                                  title: Text(context.t('changeUserRole')),
                                  subtitle: Text(context.t('currentRole', args: [user.role.toUpperCase()])),
                                  onTap: () => _showChangeRoleDialog(context, user.role),
                                  tileColor: Colors.redAccent.withAlpha(15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ],
                            );
                          }
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updatePhoto(BuildContext context, {required bool isCover}) async {
    final mediaService = MediaService();
    final cloudinaryService = CloudinaryService();
    final userService = UserService();

    final bytes = await mediaService.pickImage();

    if (bytes != null) {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('uploadingPhoto'))),
        );
      }

      final fileName = 'profile_${userId}_${isCover ? 'cover' : 'avatar'}_${DateTime.now().millisecondsSinceEpoch}';
      final url = await cloudinaryService.uploadFile(bytes, fileName, 'profiles');

      if (url != null) {
        await userService.updateProfile(
          userId,
          photoUrl: isCover ? null : url,
          coverUrl: isCover ? url : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('photoUpdated'))),
          );
        }
      }
    }
  }

  void _showChangeRoleDialog(BuildContext context, String currentRole) {
    String selectedRole = currentRole;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('changeRole')),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['user', 'vip', 'admin', 'developer'].map((role) {
              return RadioListTile<String>(
                title: Text(role.toUpperCase()),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  if (value != null) setState(() => selectedRole = value);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await UserService().updateUserRole(userId, selectedRole);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('roleUpdated'))),
                );
              }
            },
            child: Text(context.t('apply')),
          ),
        ],
      ),
    );
  }

  void _blockUser(BuildContext context, String blockUserId, String name) async {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('blockUser')),
        content: Text(context.t('blockConfirm', args: [name])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('block'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
        'blocking': FieldValue.arrayUnion([blockUserId]),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('blockedMsg', args: [name]))),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildInfoSection(BuildContext context, String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildCircleAction(BuildContext context, IconData icon, String label, {bool isError = false, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: isError 
                  ? Colors.red.withAlpha(20) 
                  : Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
              child: Icon(icon, color: isError ? Colors.red : Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: isError ? Colors.red : null)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    Color badgeColor;
    switch (role) {
      case 'developer':
        badgeColor = Colors.deepPurpleAccent;
        break;
      case 'admin':
        badgeColor = Colors.redAccent;
        break;
      case 'vip':
        badgeColor = Colors.orange;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
