import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/font_size_provider.dart';
import '../../utils/translations.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('appearance'))),
      body: Consumer2<ThemeProvider, FontSizeProvider>(
        builder: (context, themeProvider, fontSizeProvider, child) {
          return ListView(
            children: [
              const SizedBox(height: 8),
              // Dark Mode
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: colorScheme.surfaceContainerHighest.withAlpha(60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: Text(context.t('darkMode')),
                  subtitle: Text(context.t('darkModeSub')),
                  secondary: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 20, color: colorScheme.primary),
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
              ),
              const SizedBox(height: 16),

              // Font Size
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: colorScheme.surfaceContainerHighest.withAlpha(60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withAlpha(80),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.format_size_rounded, size: 20, color: colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.t('fontSize'), style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                              Text(context.t(fontSizeProvider.labelKey), style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: fontSizeProvider.scale,
                        min: 0.85,
                        max: 1.3,
                        divisions: 3,
                        label: context.t(fontSizeProvider.labelKey),
                        onChanged: (v) => fontSizeProvider.setScale(v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Wallpaper
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: colorScheme.surfaceContainerHighest.withAlpha(60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.wallpaper_rounded, size: 20, color: colorScheme.primary),
                  ),
                  title: Text(context.t('wallpaper'), style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  subtitle: Text(context.t('wallpaperSub'), style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                  onTap: () {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
