import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class GoogleMapsAvailability {
  static const channel = MethodChannel('parchapp/google_places');
  static Future<bool> isConfigured() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await channel.invokeMethod<bool>('isConfigured') ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
