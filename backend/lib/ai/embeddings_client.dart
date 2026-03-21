import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class EmbeddingsClient {
  Future<List<double>> embed(String text);
}

class EmbeddingsFactory {
  static EmbeddingsClient create() {
    const provider = String.fromEnvironment(
      'EMBEDDING_PROVIDER',
      defaultValue: 'ollama',
    );

    if (provider == 'huggingface') {
      return HuggingFaceEmbeddingsClient();
    }

    return OllamaEmbeddingsClient();
  }
}

class OllamaEmbeddingsClient implements EmbeddingsClient {
  OllamaEmbeddingsClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<double>> embed(String text) async {
    const baseUrl = String.fromEnvironment(
      'OLLAMA_BASE_URL',
      defaultValue: 'http://localhost:11434',
    );
    const model = String.fromEnvironment(
      'OLLAMA_EMBEDDING_MODEL',
      defaultValue: 'nomic-embed-text',
    );

    final response = await _client.post(
      Uri.parse('$baseUrl/api/embeddings'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'model': model,
        'prompt': text,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Ollama embeddings error: ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final values = (payload['embedding'] as List<dynamic>?) ?? <dynamic>[];
    return values.map((dynamic e) => (e as num).toDouble()).toList();
  }
}

class HuggingFaceEmbeddingsClient implements EmbeddingsClient {
  HuggingFaceEmbeddingsClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<double>> embed(String text) async {
    const token = String.fromEnvironment('HUGGING_FACE_API_TOKEN');
    const model = String.fromEnvironment(
      'HUGGING_FACE_EMBEDDING_MODEL',
      defaultValue: 'sentence-transformers/all-MiniLM-L6-v2',
    );

    if (token.isEmpty) {
      throw Exception(
        'HUGGING_FACE_API_TOKEN is required for Hugging Face embeddings.',
      );
    }

    final response = await _client.post(
      Uri.parse('https://api-inference.huggingface.co/models/$model'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'inputs': text,
        'options': <String, dynamic>{'wait_for_model': true},
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Hugging Face embeddings error: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return _normalizeEmbeddings(decoded);
  }

  List<double> _normalizeEmbeddings(dynamic payload) {
    if (payload is List<dynamic>) {
      if (payload.isEmpty) {
        return <double>[];
      }

      final first = payload.first;
      if (first is num) {
        return payload.map((dynamic e) => (e as num).toDouble()).toList();
      }

      if (first is List<dynamic>) {
        final tokenVectors = payload
            .map((dynamic row) => (row as List<dynamic>)
                .map((dynamic e) => (e as num).toDouble())
                .toList())
            .toList();

        final dimension = tokenVectors.first.length;
        final accum = List<double>.filled(dimension, 0);

        for (final row in tokenVectors) {
          for (var i = 0; i < dimension; i++) {
            accum[i] += row[i];
          }
        }

        return accum
            .map((double value) => value / tokenVectors.length)
            .toList();
      }
    }

    throw Exception('Unexpected Hugging Face embeddings format.');
  }
}
