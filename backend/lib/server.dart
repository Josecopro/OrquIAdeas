import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'ai/embeddings_client.dart';
import 'api/handlers/chat_handler.dart';
import 'api/handlers/search_handler.dart';
import 'api/routes.dart';
import 'vector_db/pinecone_client.dart';

Future<void> main() async {
  final port = int.parse(
    Platform.environment['PORT'] ??
        const String.fromEnvironment('PORT', defaultValue: '8080'),
  );

  final chatHandler = ChatHandler();
  final searchHandler = SearchHandler(
    embeddingsClient: EmbeddingsFactory.create(),
    semanticIndexService: PineconeSemanticIndexService(),
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(buildRouter(chatHandler, searchHandler).call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  stdout.writeln('Backend running on http://${server.address.host}:$port');
}
