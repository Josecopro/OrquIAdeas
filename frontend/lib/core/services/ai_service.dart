import '../config/app_config.dart';
import '../network/api_client.dart';

class AiService {
  AiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.backendBaseUrl);

  final ApiClient _apiClient;

  Future<String> ask(String question) async {
    final response = await _apiClient.post(
      '/chat',
      body: {'query': question},
    );

    return response['answer']?.toString() ??
        'No fue posible obtener una respuesta del modelo.';
  }
}
