import '../../../core/services/ai_service.dart';

class ChatRepository {
  ChatRepository({AiService? aiService})
      : _aiService = aiService ?? AiService();

  final AiService _aiService;

  Future<String> askAssistant(
    String query, {
    required String provider,
    required String model,
  }) {
    return _aiService.ask(
      query,
      provider: provider,
      model: model,
    );
  }
}
