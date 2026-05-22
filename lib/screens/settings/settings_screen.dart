import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/locale_provider.dart';
import '../../utils/translations.dart';
import 'account_settings.dart';
import 'notification_settings.dart';
import 'appearance_settings.dart';
import 'developer_mode_screen.dart';
import 'privacy_settings.dart';
import 'update_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text(context.t('notLoggedIn'))));

    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserStream(user.uid),
      builder: (context, snapshot) {
        final userModel = snapshot.data;

        return ListView(
          children: [
            const SizedBox(height: 12),
            // Account
            _buildSectionHeader(context, context.t('account')),
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: colorScheme.surfaceContainerHighest.withAlpha(60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettings())),
                leading: Hero(
                  tag: 'profile_pic',
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: userModel?.photoUrl != null ? NetworkImage(userModel!.photoUrl!) : null,
                    child: userModel?.photoUrl == null ? const Icon(Icons.person, size: 26) : null,
                  ),
                ),
                title: Text(
                  userModel?.displayName ?? 'Loading...',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  userModel?.username != null ? '@${userModel!.username}' : context.t('setUsername'),
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
              ),
            ),
            const SizedBox(height: 24),

            // Settings
            _buildSectionHeader(context, context.t('settings')),
            _buildSettingsCard(context, [
              _SettingsItem(Icons.notifications_outlined, context.t('notificationsSettings'), context.t('notificationsSub'), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettings()));
              }, colorScheme),
              _SettingsItem(Icons.palette_outlined, context.t('appearance'), context.t('appearanceSub'), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AppearanceSettings()));
              }, colorScheme),
              _SettingsItem(Icons.lock_outlined, context.t('privacySecurity'), context.t('privacySub'), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettings()));
              }, colorScheme),
              _SettingsItem(Icons.data_usage_rounded, context.t('storageData'), context.t('storageSub'), () {
                _showStorageInfo(context, colorScheme);
              }, colorScheme),
            ]),
            const SizedBox(height: 4),
            _buildLanguageTile(context, colorScheme),
            const SizedBox(height: 24),

            // Support
            _buildSectionHeader(context, context.t('support')),
            _buildSettingsCard(context, [
              _SettingsItem(Icons.info_outline, context.t('aboutApp'), context.t('version', args: ['1.0.0']), () {
                _showAboutDialog(context, colorScheme);
              }, colorScheme),
            ]),
            const SizedBox(height: 24),

            // Updates
            _buildSectionHeader(context, context.t('updates')),
            _buildSettingsCard(context, [
              _SettingsItem(Icons.system_update_rounded, context.t('updates'), context.t('latestVersion'), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateScreen()));
              }, colorScheme),
            ]),
            const SizedBox(height: 24),

            // Developer (hidden — only for users with role 'developer')
            if (userModel?.role == 'developer') ...[
              _buildSectionHeader(context, context.t('developer')),
              _buildSettingsCard(context, [
                _SettingsItem(Icons.developer_mode_rounded, context.t('developerMode'), context.t('developerSub'), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperModeScreen()));
                }, colorScheme),
              ]),
              const SizedBox(height: 24),
            ],

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                color: colorScheme.errorContainer.withAlpha(80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.t('logout')),
                        content: Text(context.t('logoutConfirm')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(context.t('logout'), style: TextStyle(color: colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _authService.signOut();
                    }
                  },
                  leading: Icon(Icons.logout_rounded, color: colorScheme.error),
                  title: Text(context.t('logout'), style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<_SettingsItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerHighest.withAlpha(60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: colorScheme.primary),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                subtitle: item.subtitle != null
                    ? Text(item.subtitle!, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant))
                    : null,
                trailing: item.onTap != null
                    ? Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant)
                    : Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant.withAlpha(80)),
              ),
              if (!isLast)
                Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant.withAlpha(60)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, ColorScheme colorScheme) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: colorScheme.surfaceContainerHighest.withAlpha(60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(context.t('language'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: localeProvider.currentLanguageCode == 'en'
                                ? colorScheme.primary.withAlpha(25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                        ),
                        title: const Text('English'),
                        trailing: localeProvider.currentLanguageCode == 'en'
                            ? Icon(Icons.check_rounded, color: colorScheme.primary)
                            : null,
                        onTap: () {
                          localeProvider.setLocale(const Locale('en'));
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: localeProvider.currentLanguageCode == 'ar'
                                ? colorScheme.primary.withAlpha(25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('🇸🇦', style: TextStyle(fontSize: 20)),
                        ),
                        title: const Text('العربية'),
                        trailing: localeProvider.currentLanguageCode == 'ar'
                            ? Icon(Icons.check_rounded, color: colorScheme.primary)
                            : null,
                        onTap: () {
                          localeProvider.setLocale(const Locale('ar'));
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.language_outlined, size: 20, color: colorScheme.primary),
            ),
            title: Text(context.t('language'), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: Text(localeProvider.currentLanguageName, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
          ),
        );
      },
    );
  }

  void _showStorageInfo(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(Icons.storage_rounded, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(context.t('storageData'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _storageRow(context, context.t('cacheSize'), context.t('cacheValue')),
            const Divider(height: 1),
            _storageRow(context, context.t('autoDownload'), context.t('wifiOnly')),
            const Divider(height: 1),
            _storageRow(context, context.t('saveToGallery'), context.t('offline')),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('clearCache')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storageRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, ColorScheme colorScheme) {
    showAboutDialog(
      context: context,
      applicationName: context.t('appName'),
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.forum_rounded, color: Colors.white, size: 28),
      ),
      children: [
        Text(context.t('appDescription')),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsItem(this.icon, this.title, this.subtitle, this.onTap, ColorScheme colorScheme);
}
