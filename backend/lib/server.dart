import 'dart:io';


import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'api/handlers/chat_handler.dart';
import 'api/routes.dart';

Future<void> main() async {
  final port = int.parse(
    Platform.environment['PORT'] ??
        const String.fromEnvironment('PORT', defaultValue: '8080'),
  );

  final chatHandler = ChatHandler();

    final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(buildRouter(chatHandler).call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  stdout.writeln('Backend running on http://${server.address.host}:$port');
}
