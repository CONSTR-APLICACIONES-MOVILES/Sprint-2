import 'dart:convert';
import 'package:flutter/foundation.dart';

Map<String, dynamic> decodeOfflineDocument(String raw) =>
    Map<String, dynamic>.from(jsonDecode(raw) as Map);
String encodeOfflineDocument(Map<String, dynamic> data) => jsonEncode(data);

/// Native compute runs JSON work on a separate isolate. The serialized storage
/// queue still owns all writes; workers receive a snapshot and never write it.
/// Web compute uses the browser event loop, not a background thread.
class OfflineDocumentCodec {
  const OfflineDocumentCodec();
  Future<Map<String, dynamic>> decode(String raw) => raw.length >= 32768
      ? compute(decodeOfflineDocument, raw, debugLabel: 'offline-cache-decode')
      : Future.value(decodeOfflineDocument(raw));
  Future<String> encode(Map<String, dynamic> data) {
    final cache = data['cache'] as Map? ?? {};
    final heavy = cache.length >= 8 ||
        cache.values.any((v) =>
            v is Map &&
            v['data'] is Map &&
            ((v['data']['alerts'] as List?)?.length ??
                    (v['data']['activities'] as List?)?.length ??
                    0) >=
                100);
    return heavy
        ? compute(encodeOfflineDocument, data,
            debugLabel: 'offline-cache-encode')
        : Future.value(encodeOfflineDocument(data));
  }
}
