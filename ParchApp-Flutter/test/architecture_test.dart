import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature imports respect presentation/domain/data boundaries', () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final imports = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      final source = file.readAsStringSync();
      for (final match in imports.allMatches(source)) {
        final uri = match.group(1)!;
        final target = uri.startsWith('package:parchapp/')
            ? uri.replaceFirst('package:parchapp/', 'lib/')
            : uri.contains(':')
                ? uri
                : file.absolute.uri.resolve(uri).path;
        if (path.contains('/domain/')) {
          expect(target, isNot(contains('/presentation/')), reason: path);
          expect(target, isNot(contains('/data/')), reason: path);
          expect(target, isNot(contains('/app/')), reason: path);
          expect(
              uri.startsWith('package:') &&
                  !uri.startsWith('package:parchapp/'),
              isFalse,
              reason: '$path must remain pure Dart');
        }
        if (path.contains('/presentation/')) {
          expect(target, isNot(contains('/data/')), reason: path);
          expect(target, isNot(contains('/dependency_injection/')),
              reason: path);
        }
        if (path.contains('/data/')) {
          expect(target, isNot(contains('/presentation/')), reason: path);
          expect(target, isNot(contains('/app/')), reason: path);
        }
        if (path.contains('/view_models/')) {
          expect(target, isNot(contains('/app/')), reason: path);
          expect(uri, isNot(contains('go_router')), reason: path);
        }
      }
      if (path.contains('/view_models/')) {
        expect(
            RegExp(r'\b(BuildContext|Navigator|ViewContract)\b')
                .hasMatch(source),
            isFalse,
            reason: '$path must expose state without controlling a View');
      }
    }
  });

  test('features have no parallel MVP roots', () {
    for (final feature
        in Directory('lib/features').listSync().whereType<Directory>()) {
      for (final child in feature.listSync().whereType<Directory>()) {
        // Git does not track empty local folders left after a migration.
        if (!child
            .listSync(recursive: true)
            .whereType<File>()
            .any((file) => file.path.endsWith('.dart'))) {
          continue;
        }
        final name =
            child.uri.pathSegments.where((part) => part.isNotEmpty).last;
        expect(['presentation', 'domain', 'data'], contains(name),
            reason: child.path);
      }
    }
  });
}
