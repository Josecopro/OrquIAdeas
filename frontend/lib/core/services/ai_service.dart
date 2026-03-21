import '../config/app_config.dart';
import '../network/api_client.dart';
import '../../features/search/domain/semantic_result.dart';

class AiService {
  AiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.backendBaseUrl);

  final ApiClient _apiClient;

  Future<String> ask(
    String question, {
    String provider = 'ollama',
    String model = 'llama3',
  }) async {
    final response = await _apiClient.post(
      '/chat',
      body: {
        'query': question,
        'provider': provider,
        'model': model,
      },
    );

    return response['answer']?.toString() ??
        'No fue posible obtener una respuesta del modelo.';
  }

  Future<SemanticSearchResult> semanticSearch({
    required String query,
    required int topK,
    required String provider,
    required String model,
  }) async {
    final response = await _apiClient.post(
      '/semantic-search',
      body: <String, dynamic>{
        'query': query,
        'topK': topK,
        'provider': provider,
        'model': model,
      },
    );

    return SemanticSearchResult.fromJson(response);
  }
}
