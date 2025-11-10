import 'dart:convert';

class VersionInfo {
  final String? currentVersion;
  final String? latestVersion;
  final bool? updateAvailable;
  final String? downloadUrl;
  final String rawBody;

  VersionInfo({
    this.currentVersion,
    this.latestVersion,
    this.updateAvailable,
    this.downloadUrl,
    required this.rawBody,
  });

  factory VersionInfo.fromResponseBody(String body) {
    try {
      final dynamic decoded = body.isNotEmpty ? jsonDecode(body) : null;
      if (decoded is Map<String, dynamic>) {
        return VersionInfo(
          currentVersion: decoded['currentVersion']?.toString(),
          latestVersion: decoded['latestVersion']?.toString(),
          updateAvailable: decoded['updateAvailable'] as bool?,
          downloadUrl: decoded['downloadUrl']?.toString(),
          rawBody: body,
        );
      } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
        final map = decoded.first as Map<String, dynamic>;
        return VersionInfo(
          currentVersion: map['currentVersion']?.toString(),
          latestVersion: map['latestVersion']?.toString(),
          updateAvailable: map['updateAvailable'] as bool?,
          downloadUrl: map['downloadUrl']?.toString(),
          rawBody: body,
        );
      }
    } catch (_) {
      // Ignore parsing errors, fallback to raw body.
    }
    return VersionInfo(rawBody: body);
  }
}

