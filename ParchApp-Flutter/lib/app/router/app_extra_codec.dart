import 'dart:convert';
import '../../features/activities/domain/entities/planning_context.dart';

class AppExtraCodec extends Codec<Object?, Object?> {
  const AppExtraCodec();
  @override
  Converter<Object?, Object?> get encoder => const _Encode();
  @override
  Converter<Object?, Object?> get decoder => const _Decode();
}

class _Encode extends Converter<Object?, Object?> {
  const _Encode();
  @override
  Object? convert(Object? input) => input is PlanningContext
      ? {
          'kind': 'planning',
          'data': {
            ...input.toMap(),
            'comparisonId': input.comparisonId,
            'expiresAt': input.expiresAt?.toUtc().toIso8601String()
          }
        }
      : input;
}

class _Decode extends Converter<Object?, Object?> {
  const _Decode();
  @override
  Object? convert(Object? input) => input is Map && input['kind'] == 'planning'
      ? PlanningContext.fromMap(Map<String, dynamic>.from(input['data'] as Map))
      : input;
}
