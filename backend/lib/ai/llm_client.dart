import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class LlmClient {
  Future<String> generate({required String prompt, required String model});
}

class LlmFactory {
  static LlmClient create(String provider) {
    if (provider == 'huggingface') {
      return HuggingFaceClient();
    }

    return OllamaClient();
  }
}

class OllamaClient implements LlmClient {
  OllamaClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> generate({
    required String prompt,
    required String model,
  }) async {
    const baseUrl = String.fromEnvironment(
      'OLLAMA_BASE_URL',
      defaultValue: 'http://localhost:11434',
    );

    final response = await _client.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'model': model.isEmpty ? 'llama3' : model,
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Ollama error: ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['response'] ?? '').toString();
  }
}

class HuggingFaceClient implements LlmClient {
  HuggingFaceClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> generate({
    required String prompt,
    required String model,
  }) async {
    const token = String.fromEnvironment('HUGGING_FACE_API_TOKEN');
    const defaultModel = String.fromEnvironment(
      'HUGGING_FACE_MODEL',
      defaultValue: 'meta-llama/Meta-Llama-3-8B-Instruct',
    );

    if (token.isEmpty) {
      throw Exception('HUGGING_FACE_API_TOKEN is required for Hugging Face.');
    }

    final targetModel = model.isEmpty ? defaultModel : model;

    final response = await _client.post(
      Uri.parse('https://api-inference.huggingface.co/models/$targetModel'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'inputs': prompt,
        'parameters': <String, dynamic>{
          'max_new_tokens': 300,
          'temperature': 0.3,
          'return_full_text': false,
        },
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Hugging Face error: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        return (first['generated_text'] ?? '').toString();
      }
    }

    if (decoded is Map<String, dynamic>) {
      return (decoded['generated_text'] ?? decoded['error'] ?? '').toString();
    }

    return 'No response from Hugging Face model.';
  }
}
