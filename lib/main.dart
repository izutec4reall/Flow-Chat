import 'dart:io' show Directory, File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/presence_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'services/device_info_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'theme/font_size_provider.dart';
import 'theme/locale_provider.dart';
import 'utils/version.dart';
import 'utils/translations.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } else {
      await Firebase.initializeApp();
    }
    await NotificationService.init();
  } catch (e) {
    runApp(_ConfigErrorApp('$e'));
    return;
  }

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Custom Error Boundary
  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We are working on fixing this issue. Please restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (isDebug) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  };

  if (FirebaseAuth.instance.currentUser != null) {
    PresenceService().initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const FlowChatApp(),
    ),
  );
}

class FlowChatApp extends StatefulWidget {
  const FlowChatApp({super.key});

  @override
  State<FlowChatApp> createState() => _FlowChatAppState();
}

class _FlowChatAppState extends State<FlowChatApp> with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final _userService = UserService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true);
    // Listen for auth state changes to clean up presence on logout
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        // User logged out - presence was already set offline
      } else {
        PresenceService().initialize();
        _updateStatus(true);
        _saveDeviceInfo(user.uid);
      }
    });
    // Handle pending notification navigation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotification();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    final user = _authService.currentUser;
    if (user != null) {
      _userService.updateOnlineStatus(user.uid, isOnline);
    }
  }

  void _checkPendingNotification() {
    final chatId = NotificationService.pendingChatId;
    if (chatId == null) return;
    NotificationService.clearPendingChat();
    final user = _authService.currentUser;
    if (user == null) return;
    // Look up chat info to determine PM vs group
    FirebaseFirestore.instance.collection('chats').doc(chatId).get().then((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      final isGroup = data['isGroup'] == true;
      final otherUserId = participants.where((id) => id != user.uid).firstOrNull ?? '';
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            isGroup: isGroup,
            otherUserId: otherUserId,
            otherUserName: '',
          ),
        ),
      );
    });
  }

  Future<void> _saveDeviceInfo(String uid) async {
    try {
      final info = await DeviceInfoService.getDeviceInfo();
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'deviceInfo': info},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, FontSizeProvider, LocaleProvider>(
      builder: (context, themeProvider, fontSizeProvider, localeProvider, child) {
        final langCode = localeProvider.currentLanguageCode;
        return MaterialApp(
          navigatorKey: _FlowChatAppState.navigatorKey,
          title: 'Flow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(langCode),
          darkTheme: AppTheme.darkTheme(langCode),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: localeProvider.locale,
          supportedLocales: localeProvider.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
          builder: (context, child) {
            return _ConfigWrapper(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: fontSizeProvider.scale,
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}

class _ConfigWrapper extends StatefulWidget {
  final Widget child;
  const _ConfigWrapper({required this.child});

  @override
  State<_ConfigWrapper> createState() => _ConfigWrapperState();
}

class _ConfigWrapperState extends State<_ConfigWrapper> {
  static final Set<String> _appPasswordEntered = {};
  static final Set<String> _appPasswordFlagged = {};
  static String _flagDirPath = '';

  static Future<String> _getFlagDir() async {
    if (_flagDirPath.isNotEmpty) return _flagDirPath;
    final dir = await getApplicationDocumentsDirectory();
    _flagDirPath = '${dir.path}/.cfg';
    await Directory(_flagDirPath).create(recursive: true);
    return _flagDirPath;
  }

  static String _flagPath(String uid) {
    final h = uid.length > 8 ? uid.substring(0, 8) : uid;
    return '$_flagDirPath/.$h';
  }

  static Future<bool> _flagExists(String uid) async {
    await _getFlagDir();
    return File(_flagPath(uid)).exists();
  }

  static Future<void> _writeFlag(String uid) async {
    await _getFlagDir();
    await File(_flagPath(uid)).writeAsString('1');
    _appPasswordFlagged.add(uid);
  }

  @override
  void initState() {
    super.initState();
    _getFlagDir();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: uid != null
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : const Stream.empty(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final isDeveloper = userData?['role'] == 'developer';
        final isBanned = userData?['banned'] == true;

        if (!isDeveloper && isBanned && uid != null) {
          return _BannedScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('config').doc('app').snapshots(),
          builder: (context, snapshot) {
            final config = snapshot.data?.data() as Map<String, dynamic>? ?? {};

            final appPassword = config['appPassword'] as String?;
            if (!isDeveloper && appPassword != null && appPassword.isNotEmpty && uid != null) {
              final entered = _appPasswordEntered.contains(uid);
              final flagged = _appPasswordFlagged.contains(uid);
              if (!entered) {
                if (!flagged) {
                  return FutureBuilder<bool>(
                    future: _flagExists(uid),
                    builder: (context, fs) {
                      if (fs.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (fs.data == true) {
                        _appPasswordEntered.add(uid);
                        _appPasswordFlagged.add(uid);
                        return widget.child;
                      }
                      return _AppPasswordScreen(
                        password: appPassword,
                        uid: uid,
                        onVerified: () {
                          _appPasswordEntered.add(uid);
                          _writeFlag(uid);
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  );
                }
                _appPasswordEntered.add(uid);
              }
            }

            if (!isDeveloper) {
              if (config['maintenanceMode'] == true) {
                return _MaintenanceScreen(message: config['maintenanceMessage'] ?? 'Under maintenance');
              }
              final minVersion = config['minVersion'] as String?;
              final apkUrl = config['apkUrl'] as String?;
              if (minVersion != null && _compareVersion(appVersion, minVersion) < 0) {
                return _ForceUpdateScreen(currentVersion: appVersion, minVersion: minVersion, apkUrl: apkUrl);
              }
              final broadcast = config['broadcast'] as Map?;
              final showBanner = broadcast?['active'] == true && broadcast?['message'] != null;
              if (showBanner) {
                return _BroadcastWrapper(message: broadcast!['message'] as String, child: widget.child);
              }
            }

            return widget.child;
          },
        );
      },
    );
  }

  int _compareVersion(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (partsA[i] < partsB[i]) return -1;
      if (partsA[i] > partsB[i]) return 1;
    }
    return 0;
  }
}

class _MaintenanceScreen extends StatelessWidget {
  final String message;
  const _MaintenanceScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('Under Maintenance', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForceUpdateScreen extends StatelessWidget {
  final String currentVersion;
  final String minVersion;
  final String? apkUrl;
  const _ForceUpdateScreen({required this.currentVersion, required this.minVersion, required this.apkUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update_rounded, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                context.t('updateRequired'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.t('updateRequiredDesc', args: [minVersion]),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                '${context.t('currentVersion')}: $currentVersion',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withAlpha(150)),
              ),
              const SizedBox(height: 32),
              if (apkUrl != null && apkUrl!.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => _downloadUpdate(context, apkUrl!),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(context.t('downloadUpdate')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(240, 48),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                )
              else
                Text(
                  context.t('updateNoLink'),
                  style: TextStyle(color: colorScheme.error, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadUpdate(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('updateError')}: $url')),
        );
      }
    }
  }
}

class _BroadcastWrapper extends StatelessWidget {
  final String message;
  final Widget child;
  const _BroadcastWrapper({required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.primary,
          child: Row(
            children: [
              Icon(Icons.campaign_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13))),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _BannedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 80, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 24),
              Text(context.t('bannedTitle'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(context.t('bannedDesc'), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: Text(context.t('signOut')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppPasswordScreen extends StatefulWidget {
  final String password;
  final String uid;
  final VoidCallback onVerified;
  const _AppPasswordScreen({required this.password, required this.uid, required this.onVerified});

  @override
  State<_AppPasswordScreen> createState() => _AppPasswordScreenState();
}

class _AppPasswordScreenState extends State<_AppPasswordScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(context.t('appPasswordRequired'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(context.t('appPasswordHint'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: context.t('appPasswordHint'),
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_controller.text == widget.password) {
                    widget.onVerified();
                  } else {
                    setState(() => _error = context.t('incorrectPassword'));
                  }
                },
                child: Text(context.t('verify')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigErrorApp extends StatelessWidget {
  final String error;
  const _ConfigErrorApp(this.error);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase not configured',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Setup:\n'
                    '1. cp .env.example .env\n'
                    '2. Fill in your Firebase values\n'
                    '3. ./run.sh',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'See README.md for full setup instructions.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
