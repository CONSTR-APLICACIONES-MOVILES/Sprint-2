import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/repositories/external_actions.dart';

class PlatformExternalActions implements ExternalActions {
  const PlatformExternalActions();
  @override
  String? enrollmentUrl(String token) {
    const configured = String.fromEnvironment('APP_LINK_BASE_URL');
    final base = configured.isNotEmpty
        ? Uri.tryParse(configured)
        : kIsWeb
            ? Uri.base
            : null;
    if (base == null || !['http', 'https'].contains(base.scheme)) return null;
    return base
        .replace(fragment: '/join/${Uri.encodeComponent(token)}', query: '')
        .toString();
  }

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
  String _outcome(ShareResult result) => switch (result.status) {
        ShareResultStatus.success =>
          'Shared with the selected app. Delivery or calendar import is not confirmed.',
        ShareResultStatus.dismissed => 'Sharing cancelled.',
        ShareResultStatus.unavailable =>
          'The platform did not confirm sharing. Check the destination or browser download.',
      };
  @override
  Future<String> shareText(String text) async =>
      _outcome(await SharePlus.instance.share(ShareParams(
          text: text, sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1))));
  @override
  Future<String> shareCalendar(String fileName, String content) async =>
      _outcome(await SharePlus.instance.share(ShareParams(
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
          files: [
            XFile.fromData(Uint8List.fromList(utf8.encode(content)),
                mimeType: 'text/calendar', name: fileName)
          ],
          fileNameOverrides: [
            fileName
          ])));
  @override
  Future<bool> openResource(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
      throw StateError('Invalid resource URL.');
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
