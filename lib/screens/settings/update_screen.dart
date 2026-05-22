import 'package:flutter/material.dart';
import '../../services/update_service.dart';
import '../../services/device_info_service.dart';
import '../../utils/translations.dart';
import '../../utils/version.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  ReleaseInfo? _release;
  bool _loading = true;
  String? _error;
  bool? _hasUpdate;
  String? _deviceArch;

  @override
  void initState() {
    super.initState();
    _detectArch();
    _checkUpdate();
  }

  Future<void> _detectArch() async {
    final arch = await DeviceInfoService.getDeviceArch();
    if (mounted) setState(() => _deviceArch = arch);
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final release = await UpdateService.fetchLatestRelease();
      if (!mounted) return;
      if (release == null) {
        setState(() {
          _loading = false;
          _error = context.t('updateCheckFailed');
        });
        return;
      }
      setState(() {
        _release = release;
        _loading = false;
        _hasUpdate = UpdateService.compareVersions(appVersion, release.version) < 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.t('updateCheckFailed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('updates'))),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.onSurfaceVariant.withAlpha(100)),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: _checkUpdate,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.t('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final release = _release!;
    final hasUpdate = _hasUpdate!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status card
        Card(
          color: hasUpdate ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  hasUpdate ? Icons.system_update_rounded : Icons.check_circle_rounded,
                  size: 48,
                  color: hasUpdate ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasUpdate ? context.t('updateAvailable') : context.t('appUpToDate'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasUpdate
                            ? '${context.t('latestVersion')}: ${release.version}'
                            : '${context.t('currentVersion')}: $appVersion',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Version info
        Text(context.t('versionInfo'), style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(context, context.t('currentVersion'), appVersion, colorScheme),
                const Divider(),
                _infoRow(context, context.t('latestVersion'), release.version, colorScheme),
                const Divider(),
                _infoRow(context, context.t('releaseDate'), release.publishedAt.split('T').firstOrNull ?? '', colorScheme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Download buttons
        if (release.assets.isNotEmpty) ...[
          Text(context.t('downloads'), style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 8),
          if (_deviceArch != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${context.t('yourDevice')}: ${DeviceInfoService.archLabel(_deviceArch)}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ...release.assets.map((asset) {
            final isMatch = _deviceArch != null && asset.name.contains(_deviceArch!);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: isMatch ? colorScheme.primaryContainer : null,
                child: ListTile(
                  leading: Icon(
                    isMatch ? Icons.check_circle_rounded : Icons.android_rounded,
                    color: isMatch ? colorScheme.onPrimaryContainer : null,
                  ),
                  title: Text(
                    asset.name,
                    style: isMatch
                        ? TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  subtitle: Text(asset.formattedSize),
                  trailing: FilledButton.tonal(
                    onPressed: () => UpdateService.downloadApk(asset.downloadUrl),
                    child: Text(context.t('download')),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Changelog
        Text(context.t('changelog'), style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              release.body.isNotEmpty ? release.body : context.t('noChangelog'),
              style: TextStyle(color: colorScheme.onSurface, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // View all releases link
        OutlinedButton.icon(
          onPressed: () => UpdateService.downloadApk('https://github.com/izutec4reall/Flow-Chat/releases'),
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(context.t('viewAllReleases')),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
