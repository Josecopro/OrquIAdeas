import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'handlers/chat_handler.dart';

Router buildRouter(ChatHandler chatHandler) {
  final router = Router();

  router.get('/health', (Request request) {
    return Response.ok(
      jsonEncode(<String, dynamic>{'status': 'ok'}),
      headers: const <String, String>{'Content-Type': 'application/json'},
    );
  });

  router.post('/chat', chatHandler.handle);

  return router;
}
