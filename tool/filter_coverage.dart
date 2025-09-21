import 'dart:io';

/// Removes generated files from coverage reporting.
///
/// Invoke after running `flutter test --coverage` to strip `lib/types.dart`
/// entries from `coverage/lcov.info`.
Future<void> main(List<String> arguments) async {
  final coveragePath =
      arguments.isNotEmpty ? arguments.first : 'coverage/lcov.info';
  final coverageFile = File(coveragePath);

  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${coverageFile.path}');
    exitCode = 1;
    return;
  }

  final lines = await coverageFile.readAsLines();
  final buffer = StringBuffer();
  var skipRecord = false;
  var removedRecords = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      final normalizedPath = line.substring(3).trim().replaceAll('\\', '/');
      skipRecord = normalizedPath.endsWith('lib/types.dart');
      if (skipRecord) {
        removedRecords += 1;
        continue;
      }
    }

    if (skipRecord) {
      if (line == 'end_of_record') {
        skipRecord = false;
      }
      continue;
    }

    buffer.writeln(line);
  }

  await coverageFile.writeAsString(buffer.toString());
  stdout.writeln(
    'Removed $removedRecords coverage entr${removedRecords == 1 ? 'y' : 'ies'} for lib/types.dart',
  );
}
