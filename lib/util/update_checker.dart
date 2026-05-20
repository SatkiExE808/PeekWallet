import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'peek_logger.dart';

/// Outcome of a single update probe.
@immutable
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.checkedAt,
    required this.currentBuildTime,
    required this.latestReleaseAt,
    required this.latestTag,
    required this.assetUrl,
    required this.releaseUrl,
    required this.isUpdateAvailable,
    this.error,
  });

  final DateTime checkedAt;
  /// Build time of the running APK (from --dart-define=BUILD_TIME=…
  /// passed by CI). Null on local debug builds.
  final DateTime? currentBuildTime;
  /// `published_at` of the latest GitHub release.
  final DateTime? latestReleaseAt;
  /// `tag_name` of the latest release (e.g. "latest" or "v1.2.3").
  final String? latestTag;
  /// Direct download URL of the first `.apk` asset on the latest
  /// release, if any. Null on releases without an APK attached.
  final String? assetUrl;
  /// HTML URL of the release page (the user-friendly "browse the
  /// release notes" link).
  final String? releaseUrl;
  /// True when the latest release is newer than the running build.
  /// Always false when [currentBuildTime] is null — debug builds
  /// don't have an embedded build time to compare against.
  final bool isUpdateAvailable;
  final String? error;

  bool get hasError => error != null;
}

/// Hits the GitHub Releases API for `SatkiExE808/PeekWallet` and
/// compares the latest release's publish timestamp against the
/// running APK's build time.
///
/// Why timestamps and not SemVer: the project's CI publishes to a
/// rolling "latest" tag on every push to main, so there's no monotonic
/// tag to compare against. The release's `published_at` is the next
/// best signal — it advances on every CI build.
///
/// Why timestamps and not commit SHA: comparing SHAs would also work
/// but only tells you "different", not "newer". A user on a hand-
/// built APK from a feature branch would see a phantom "update
/// available" pointing back to main — confusing.
class UpdateChecker {
  UpdateChecker._();
  static final UpdateChecker I = UpdateChecker._();

  static const _githubOwner = 'SatkiExE808';
  static const _githubRepo = 'PeekWallet';
  static const _releasesEndpoint =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

  /// Embedded at build time by CI: `flutter build apk
  /// --dart-define=BUILD_TIME=$(git log -1 --format=%aI)`. Falls
  /// back to "" on local debug builds (no value provided).
  static const _buildTimeEnv = String.fromEnvironment('BUILD_TIME');

  UpdateCheckResult? _lastResult;
  UpdateCheckResult? get lastResult => _lastResult;

  DateTime? get buildTime {
    if (_buildTimeEnv.isEmpty) return null;
    return DateTime.tryParse(_buildTimeEnv);
  }

  /// Get the running app version + build number from pubspec metadata.
  Future<String> currentDisplayVersion() async {
    final pkg = await PackageInfo.fromPlatform();
    return '${pkg.version}+${pkg.buildNumber}';
  }

  /// Probe GitHub for the latest release. Network failures are
  /// captured in the result rather than thrown so callers can
  /// render a status message instead of needing a try/catch.
  Future<UpdateCheckResult> check() async {
    final now = DateTime.now().toUtc();
    final buildTime = this.buildTime;
    try {
      final resp = await http
          .get(Uri.parse(_releasesEndpoint),
              headers: const {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        // GitHub's unauthenticated rate limit is 60 req/IP/hour. 403
        // with X-RateLimit-Remaining: 0 is the common hit; surface
        // a friendly retry message instead of the raw code.
        String msg;
        if (resp.statusCode == 403 &&
            resp.headers['x-ratelimit-remaining'] == '0') {
          msg = 'Rate-limited by GitHub. Try again in an hour.';
        } else if (resp.statusCode == 404) {
          msg = 'No releases published yet.';
        } else {
          msg = 'GitHub API returned ${resp.statusCode}';
        }
        return _lastResult = UpdateCheckResult(
          checkedAt: now,
          currentBuildTime: buildTime,
          latestReleaseAt: null,
          latestTag: null,
          assetUrl: null,
          releaseUrl: null,
          isUpdateAvailable: false,
          error: msg,
        );
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final publishedRaw = json['published_at'] as String?;
      final tag = json['tag_name'] as String?;
      final htmlUrl = json['html_url'] as String?;
      final assets = (json['assets'] as List?) ?? const [];
      String? apkUrl;
      for (final a in assets) {
        if (a is! Map) continue;
        final name = (a['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = a['browser_download_url'] as String?;
          break;
        }
      }
      final publishedAt = publishedRaw == null
          ? null
          : DateTime.tryParse(publishedRaw)?.toUtc();
      // A release publishes ~seconds to a few minutes AFTER the
      // build that produced its APK finished (asset upload + release
      // create are sequential after `flutter build apk`). With a
      // strict isAfter() comparison, the freshly-installed APK from
      // release R sees R.publishedAt > buildTime by ~30s and
      // phantom-flags itself as "update available" pointing back at
      // itself. A 10-minute slack window is wider than any
      // realistic CI build → release lag, and narrower than the
      // ~1h cadence of typical pushes, so genuine updates still
      // surface promptly.
      const publishLag = Duration(minutes: 10);
      final available = (buildTime != null &&
          publishedAt != null &&
          publishedAt.isAfter(buildTime.add(publishLag)));
      return _lastResult = UpdateCheckResult(
        checkedAt: now,
        currentBuildTime: buildTime,
        latestReleaseAt: publishedAt,
        latestTag: tag,
        assetUrl: apkUrl,
        releaseUrl: htmlUrl,
        isUpdateAvailable: available,
      );
    } on SocketException catch (e) {
      PeekLogger.I.log('update', 'check socket failure: $e');
      return _lastResult = UpdateCheckResult(
        checkedAt: now,
        currentBuildTime: buildTime,
        latestReleaseAt: null,
        latestTag: null,
        assetUrl: null,
        releaseUrl: null,
        isUpdateAvailable: false,
        error: 'No network — try again on Wi-Fi.',
      );
    } on TimeoutException {
      return _lastResult = UpdateCheckResult(
        checkedAt: now,
        currentBuildTime: buildTime,
        latestReleaseAt: null,
        latestTag: null,
        assetUrl: null,
        releaseUrl: null,
        isUpdateAvailable: false,
        error: 'GitHub timed out — try again in a minute.',
      );
    } catch (e) {
      PeekLogger.I.log('update', 'check failed: $e');
      return _lastResult = UpdateCheckResult(
        checkedAt: now,
        currentBuildTime: buildTime,
        latestReleaseAt: null,
        latestTag: null,
        assetUrl: null,
        releaseUrl: null,
        isUpdateAvailable: false,
        error: e.toString(),
      );
    }
  }
}
