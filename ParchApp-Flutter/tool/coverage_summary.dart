import 'dart:convert';
import 'dart:io';

void main() {
  final report = File('coverage/lcov.info');
  if (!report.existsSync()) {
    throw StateError('Run flutter test --coverage first.');
  }
  var found = 0, hit = 0, files = 0;
  final byFile = <Map<String, Object>>[];
  String? path;
  var fileFound = 0, fileHit = 0;
  for (final line in report.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      path = line.substring(3);
      fileFound = 0;
      fileHit = 0;
    }
    if (line.startsWith('DA:')) {
      fileFound++;
      if (int.parse(line.substring(3).split(',')[1]) > 0) fileHit++;
    }
    if (line == 'end_of_record' && path != null) {
      files++;
      found += fileFound;
      hit += fileHit;
      byFile.add({
        'file': path,
        'instrumentedLines': fileFound,
        'coveredLines': fileHit
      });
    }
  }
  final summary = {
    'instrumentedFiles': files,
    'instrumentedLines': found,
    'coveredLines': hit,
    'instrumentedLineCoveragePercent': found == 0
        ? null
        : double.parse((100 * hit / found).toStringAsFixed(2)),
    'limitation':
        'LCOV reports instrumented files. This is not proof that every source file was exercised.',
    'files': byFile
  };
  File('coverage/summary.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(
      'Coverage: $hit/$found instrumented lines (${summary['instrumentedLineCoveragePercent']}%), $files files.');
  stdout.writeln(summary['limitation']);
}
