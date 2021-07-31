import 'package:logging/logging.dart';

void configureConsoleLogger(int levelIndex) {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.LEVELS[levelIndex];
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.loggerName}'
        '@${record.time} : ${record.message}');
    if (record.error != null) {
      print('Caused by: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stacktrace: ${record.stackTrace}');
    }
  });
}