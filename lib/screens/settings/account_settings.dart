import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/media_service.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final _authService = AuthService();
  final _userService = UserService();
  final _cloudinaryService = CloudinaryService();
  
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isInit = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateField(String uid, {String? displayName, String? username, String? bio}) async {
    if (username != null) {
      final available = await _userService.isUsernameAvailable(username);
      if (!available) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('usernameTaken'))));
        return;
      }
    }
    
    await _userService.updateProfile(uid, 
      displayName: displayName, 
      username: username, 
      bio: bio
    );
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('updatedSuccess'))));
  }

  Future<void> _updatePhoto(String uid, {required bool isCover}) async {
    final mediaService = MediaService();
    
    final bytes = await mediaService.pickAndCropImage(
      context: context,
      cropStyle: isCover ? CropStyle.rectangle : CropStyle.circle,
      ratioX: isCover ? 16 : 1,
      ratioY: isCover ? 9 : 1,
    );

    if (bytes != null) {
      final fileName = 'profile_${uid}_${isCover ? 'cover' : 'avatar'}_${DateTime.now().millisecondsSinceEpoch}';
      final url = await _cloudinaryService.uploadFile(bytes, fileName, 'profiles');
      
      if (url != null) {
        await _userService.updateProfile(
          uid, 
          photoUrl: isCover ? null : url,
          coverUrl: isCover ? url : null,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('photoSuccess'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text(context.t('error'))));

    return Scaffold(
      appBar: AppBar(title: Text(context.t('account'))),
      body: FutureBuilder<UserModel?>(
        future: _userService.getUser(user.uid),
        builder: (context, snapshot) {
          final userModel = snapshot.data;
          if (userModel != null && _isInit) {
            _nameController.text = userModel.displayName;
            _usernameController.text = userModel.username ?? '';
            _bioController.text = userModel.bio ?? '';
            _isInit = false;
          }

          return ListView(
            padding: const EdgeInsets.all(AppConstants.md),
            children: [
              // Cover Photo Section
              Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      image: userModel?.coverUrl != null 
                          ? DecorationImage(image: NetworkImage(userModel!.coverUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: userModel?.coverUrl == null 
                        ? const Icon(Icons.wallpaper, size: 48, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: () => _updatePhoto(user.uid, isCover: true),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: userModel?.photoUrl != null ? NetworkImage(userModel!.photoUrl!) : null,
                      child: userModel?.photoUrl == null ? const Icon(Icons.person, size: 60) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: FloatingActionButton.small(
                        onPressed: () => _updatePhoto(user.uid, isCover: false),
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _buildEditableTile(
                title: context.t('name'),
                controller: _nameController,
                icon: Icons.person_outline,
                onSave: (val) => _updateField(user.uid, displayName: val),
              ),
              const SizedBox(height: 16),
              
              _buildEditableTile(
                title: context.t('username'),
                controller: _usernameController,
                icon: Icons.alternate_email,
                prefix: '@',
                onSave: (val) => _updateField(user.uid, username: val),
              ),
              const SizedBox(height: 16),
              
              _buildEditableTile(
                title: context.t('about'),
                controller: _bioController,
                icon: Icons.info_outline,
                maxLines: 3,
                onSave: (val) => _updateField(user.uid, bio: val),
              ),
              
              const Divider(height: 40),
              ListTile(
                title: Text(context.t('email')),
                subtitle: Text(userModel?.email ?? ''),
                leading: const Icon(Icons.email_outlined),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableTile({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Function(String) onSave,
    String? prefix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            prefixText: prefix,
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => onSave(controller.text.trim()),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
