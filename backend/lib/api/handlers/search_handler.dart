import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../ai/embeddings_client.dart';
import '../../ai/llm_client.dart';
import '../../models/search_request.dart';
import '../../vector_db/semantic_index_service.dart';

class SearchHandler {
  SearchHandler({
    required EmbeddingsClient embeddingsClient,
    required SemanticIndexService semanticIndexService,
  })  : _embeddingsClient = embeddingsClient,
        _semanticIndexService = semanticIndexService;

  final EmbeddingsClient _embeddingsClient;
  final SemanticIndexService _semanticIndexService;

  Future<Response> handle(Request request) async {
    try {
      final body = await request.readAsString();
      final jsonBody = jsonDecode(body) as Map<String, dynamic>;
      final payload = SearchRequest.fromJson(jsonBody);

      if (payload.query.isEmpty) {
        return Response.badRequest(
          body: jsonEncode(<String, dynamic>{
            'error': 'The field query is required.',
          }),
          headers: const <String, String>{'Content-Type': 'application/json'},
        );
      }

      final queryVector = await _embeddingsClient.embed(payload.query);
      final contexts = await _semanticIndexService.search(
        vector: queryVector,
        query: payload.query,
        topK: payload.topK,
      );

      final llmClient = LlmFactory.create(payload.provider);
      final answer = await llmClient.generate(
        prompt: _buildRagPrompt(payload.query, contexts),
        model: payload.model,
      );

      return Response.ok(
        jsonEncode(<String, dynamic>{
          'query': payload.query,
          'topK': payload.topK,
          'answer': answer,
          'contexts': contexts
              .map((SemanticDocument document) => document.toJson())
              .toList(),
        }),
        headers: const <String, String>{'Content-Type': 'application/json'},
      );
    } catch (error) {
      return Response.internalServerError(
        body: jsonEncode(<String, dynamic>{'error': error.toString()}),
        headers: const <String, String>{'Content-Type': 'application/json'},
      );
    }
  }

  String _buildRagPrompt(String query, List<SemanticDocument> contexts) {
    final buffer = StringBuffer()
      ..writeln('Eres un asistente tecnico para caficultores.')
      ..writeln(
        'Usa solo el contexto provisto para responder en forma practica y accionable.',
      )
      ..writeln('')
      ..writeln('Contexto recuperado:');

    for (final item in contexts) {
      buffer
        ..writeln('- [${item.title}] ${item.text}')
        ..writeln(
            '  Fuente: ${item.source} (score: ${item.score.toStringAsFixed(2)})');
    }

    buffer
      ..writeln('')
      ..writeln('Pregunta: $query')
      ..writeln('')
      ..writeln('Respuesta:');

    return buffer.toString();
  }
}
