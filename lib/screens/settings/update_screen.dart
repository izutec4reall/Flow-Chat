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
  ReleaseInfo? _latest;
  List<ReleaseInfo> _allReleases = [];
  bool _loadingLatest = true;
  bool _loadingAll = true;
  String? _error;
  bool? _hasUpdate;
  String? _deviceArch;

  @override
  void initState() {
    super.initState();
    _detectArch();
    _load();
  }

  Future<void> _detectArch() async {
    final arch = await DeviceInfoService.getDeviceArch();
    if (mounted) setState(() => _deviceArch = arch);
  }

  Future<void> _load() async {
    await Future.wait([_loadLatest(), _loadAll()]);
  }

  Future<void> _loadLatest() async {
    setState(() {
      _loadingLatest = true;
      _error = null;
    });
    try {
      final release = await UpdateService.fetchLatestRelease();
      if (!mounted) return;
      if (release == null) {
        setState(() {
          _loadingLatest = false;
          _error = context.t('updateCheckFailed');
        });
        return;
      }
      setState(() {
        _latest = release;
        _loadingLatest = false;
        _hasUpdate = UpdateService.compareVersions(appVersion, release.version) < 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLatest = false;
        _error = context.t('updateCheckFailed');
      });
    }
  }

  Future<void> _loadAll() async {
    try {
      final releases = await UpdateService.fetchAllReleases();
      if (!mounted) return;
      setState(() => _allReleases = releases);
    } catch (_) {
      // non-critical
    } finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  ReleaseAsset? _bestAsset(ReleaseInfo release) {
    if (_deviceArch == null) return null;
    return release.assets.cast<ReleaseAsset?>().firstWhere(
          (a) => a!.name.contains(_deviceArch!),
          orElse: () => null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('updates'))),
      body: _loadingLatest
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _latest == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 64,
                            color: colorScheme.onSurfaceVariant.withAlpha(100)),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton.tonalIcon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(context.t('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    _StatusCard(
                      hasUpdate: _hasUpdate ?? false,
                      latestVersion: _latest?.version ?? '',
                      onTap: _load,
                    ),
                    const SizedBox(height: 20),
                    if (_latest != null) ...[
                      _QuickDownloadCard(
                        release: _latest!,
                        deviceArch: _deviceArch,
                        onDownload: _downloadRelease,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(context.t('allReleases'),
                        style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                    const SizedBox(height: 8),
                    if (_loadingAll)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (_allReleases.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(context.t('noChangelog'),
                                style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ),
                        ),
                      )
                    else
                      ..._allReleases.map((r) => _ReleaseCard(
                            release: r,
                            onTap: () => _showReleaseDetail(r),
                          )),
                  ],
                ),
    );
  }

  Future<void> _downloadRelease(ReleaseInfo release) async {
    final asset = _bestAsset(release);
    if (asset == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('noCompatibleApk'))),
      );
      return;
    }
    final ok = await UpdateService.downloadApk(asset.downloadUrl);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('downloadError'))),
      );
    }
  }

  void _showReleaseDetail(ReleaseInfo release) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReleaseDetailSheet(
        release: release,
        deviceArch: _deviceArch,
        onDownload: _downloadRelease,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool hasUpdate;
  final String latestVersion;
  final VoidCallback onTap;

  const _StatusCard({
    required this.hasUpdate,
    required this.latestVersion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = hasUpdate ? colorScheme.primaryContainer : colorScheme.secondaryContainer;
    final iconColor = hasUpdate ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              hasUpdate ? Icons.system_update_rounded : Icons.check_circle_rounded,
              size: 48,
              color: iconColor,
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
                        ? '${context.t('latestVersion')}: $latestVersion'
                        : '${context.t('currentVersion')}: $appVersion',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (hasUpdate)
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: context.t('retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickDownloadCard extends StatelessWidget {
  final ReleaseInfo release;
  final String? deviceArch;
  final void Function(ReleaseInfo) onDownload;

  const _QuickDownloadCard({
    required this.release,
    required this.deviceArch,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onDownload(release),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.download_rounded, color: colorScheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t('downloadForDevice'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      deviceArch != null
                          ? '${DeviceInfoService.archLabel(deviceArch)} · ${context.t('latestVersion')} ${release.version}'
                          : '${context.t('latestVersion')} ${release.version}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final ReleaseInfo release;
  final VoidCallback onTap;

  const _ReleaseCard({required this.release, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = release.publishedAt.length >= 10
        ? release.publishedAt.substring(0, 10)
        : release.publishedAt;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(release.tagName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Text(date,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
              if (release.body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  UpdateService.cleanMarkdown(release.body),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.download_rounded, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('${release.assets.length} ${context.t('downloads').toLowerCase()}',
                      style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                  const Spacer(),
                  Text(context.t('viewDetails'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      )),
                  Icon(Icons.chevron_right_rounded, size: 16, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseDetailSheet extends StatelessWidget {
  final ReleaseInfo release;
  final String? deviceArch;
  final void Function(ReleaseInfo) onDownload;

  const _ReleaseDetailSheet({
    required this.release,
    required this.deviceArch,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = release.publishedAt.length >= 10
        ? release.publishedAt.substring(0, 10)
        : release.publishedAt;
    final cleanBody = UpdateService.cleanMarkdown(release.body);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(release.tagName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Text(date,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              Text(context.t('changelog'),
                  style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cleanBody.isNotEmpty ? cleanBody : context.t('noChangelog'),
                  style: TextStyle(color: colorScheme.onSurface, height: 1.6, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              if (release.assets.isNotEmpty) ...[
                Text(context.t('downloads'),
                    style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                const SizedBox(height: 8),
                if (deviceArch != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: colorScheme.primaryContainer,
                      child: ListTile(
                        leading: Icon(Icons.download_rounded, color: colorScheme.onPrimaryContainer),
                        title: Text(context.t('downloadForDevice'),
                            style: TextStyle(fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer)),
                        subtitle: Text(DeviceInfoService.archLabel(deviceArch),
                            style: TextStyle(color: colorScheme.onPrimaryContainer.withAlpha(180))),
                        trailing: FilledButton(
                          onPressed: () => onDownload(release),
                          child: Text(context.t('download')),
                        ),
                      ),
                    ),
                  ),
                ...release.assets.map((asset) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Card(
                        child: ListTile(
                          leading: Icon(Icons.android_rounded, color: colorScheme.primary),
                          title: Text(asset.name, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(asset.formattedSize, style: const TextStyle(fontSize: 12)),
                          trailing: FilledButton.tonal(
                            onPressed: () => _downloadAsset(context, asset),
                            child: Text(context.t('download')),
                          ),
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadAsset(BuildContext context, ReleaseAsset asset) async {
    final ok = await UpdateService.downloadApk(asset.downloadUrl);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('downloadError'))),
      );
    }
  }
}
