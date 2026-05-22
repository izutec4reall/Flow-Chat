import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const String _repo = 'izutec4reall/Flow-Chat';
const String _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';

class ReleaseInfo {
  final String tagName;
  final String version;
  final String body;
  final List<ReleaseAsset> assets;
  final String publishedAt;

  ReleaseInfo({
    required this.tagName,
    required this.version,
    required this.body,
    required this.assets,
    required this.publishedAt,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    return ReleaseInfo(
      tagName: tag,
      version: tag.replaceFirst('v', '').replaceAll('+', '.'),
      body: json['body'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => ReleaseAsset.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;

  ReleaseAsset({required this.name, required this.downloadUrl, required this.size});

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
        name: json['name'] as String? ?? '',
        downloadUrl: json['browser_download_url'] as String? ?? '',
        size: json['size'] as int? ?? 0,
      );

  String get formattedSize {
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class UpdateService {
  static Future<ReleaseInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'User-Agent': 'Flow-App'},
      );
      if (response.statusCode != 200) return null;
      return ReleaseInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static int compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va < vb) return -1;
      if (va > vb) return 1;
    }
    return 0;
  }

  static Future<void> downloadApk(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
