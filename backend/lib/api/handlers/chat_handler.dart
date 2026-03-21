import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../ai/llm_client.dart';
import '../../models/chat_request.dart';

class ChatHandler {
  ChatHandler();

  Future<Response> handle(Request request) async {
    try {
      final body = await request.readAsString();
      final jsonBody = jsonDecode(body) as Map<String, dynamic>;
      final payload = ChatRequest.fromJson(jsonBody);

      if (payload.query.isEmpty) {
        return Response.badRequest(
          body: jsonEncode(<String, dynamic>{
            'error': 'The field query is required.',
          }),
          headers: const <String, String>{'Content-Type': 'application/json'},
        );
      }

      final prompt = _buildPrompt(payload.query);
      final llmClient = LlmFactory.create(payload.provider);
      final answer = await llmClient.generate(
        prompt: prompt,
        model: payload.model,
      );

      return Response.ok(
        jsonEncode(<String, dynamic>{
          'provider': payload.provider,
          'model': payload.model.isEmpty ? 'default' : payload.model,
          'answer': answer,
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

  String _buildPrompt(String query) {
    return '''
Eres un asistente experto en aprovechamiento sostenible de cascarilla de cafe.
Responde de forma practica para pequenos caficultores.
Pregunta del usuario: $query
''';
  }
}
