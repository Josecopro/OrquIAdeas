
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

import 'package:http/http.dart' as http;

abstract class LlmClient {
  Future<String> generate({required String prompt});
}


class LlmFactory {
  static LlmClient create() {
    // Permitir certificados autofirmados solo si la variable de entorno DART_ALLOW_BAD_CERT está en 'true'
    if (Platform.environment['DART_ALLOW_BAD_CERT'] == 'true') {
      final ioClient = IOClient(
        HttpClient()
          ..badCertificateCallback = (cert, host, port) => true,
      );
      return GeminiClient(client: ioClient);
    }
    return GeminiClient();
  }
}

class GeminiClient implements LlmClient {
  GeminiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> generate({required String prompt}) async {
    final apiKey = _resolveGeminiApiKey();
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is required for Gemini.');
    }

    final targetModel = _resolveGeminiModelDefault();

    final response = await _client.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$targetModel:generateContent?key=$apiKey',
      ),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': prompt},
            ],
          },
        ],
        'generationConfig': <String, dynamic>{
          'temperature': 0.3,
          'maxOutputTokens': 2048,
        },
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Gemini error: ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = payload['candidates'];

    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map<String, dynamic>) {
        final content = first['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List) {
            final textBuffer = StringBuffer();
            for (final part in parts) {
              if (part is Map<String, dynamic> && part['text'] != null) {
                textBuffer.write(part['text'].toString());
              }
            }

            final text = textBuffer.toString().trim();
            if (text.isNotEmpty) {
              return text;
            }
          }
        }
      }
    }

    return 'No response from Gemini model.';
  }

  String _resolveGeminiApiKey() {
    final envKey = Platform.environment['GEMINI_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    const definedKey = String.fromEnvironment('GEMINI_API_KEY');
    if (definedKey.isNotEmpty) {
      return definedKey;
    }

    return _DotEnvReader.value('GEMINI_API_KEY');
  }

  String _resolveGeminiModelDefault() {
    final envModel = Platform.environment['GEMINI_MODEL'];
    if (envModel != null && envModel.trim().isNotEmpty) {
      return envModel.trim();
    }

    const definedModel = String.fromEnvironment('GEMINI_MODEL');
    if (definedModel.isNotEmpty) {
      return definedModel;
    }

    final modelFromFile = _DotEnvReader.value('GEMINI_MODEL');
    if (modelFromFile.isNotEmpty) {
      return modelFromFile;
    }

    return 'gemini-2.0-flash';
  }
}

class _DotEnvReader {
  static Map<String, String>? _cache;

  static String value(String key) {
    _cache ??= _load();
    return _cache![key] ?? '';
  }

  static Map<String, String> _load() {
    final paths = <String>['.env', 'backend/.env'];
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }

      final lines = file.readAsLinesSync();
      final values = <String, String>{};
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) {
          continue;
        }

        final separator = line.indexOf('=');
        if (separator <= 0) {
          continue;
        }

        final key = line.substring(0, separator).trim();
        final value = line.substring(separator + 1).trim();
        if (key.isNotEmpty) {
          values[key] = value;
        }
      }

      if (values.isNotEmpty) {
        return values;
      }
    }

    return <String, String>{};
  }
}
