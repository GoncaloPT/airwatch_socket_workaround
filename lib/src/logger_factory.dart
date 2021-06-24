import 'package:logging/logging.dart';

Logger getLogger(Type forType) {
  return Logger('airwatch_socket_workaround.${forType.toString()}');
}