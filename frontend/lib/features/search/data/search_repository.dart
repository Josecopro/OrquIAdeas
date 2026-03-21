import '../../../core/services/ai_service.dart';
import '../domain/semantic_result.dart';

class SearchRepository {
  SearchRepository({AiService? aiService})
      : _aiService = aiService ?? AiService();

  final AiService _aiService;

  Future<SemanticSearchResult> semanticSearch({
    required String query,
    required int topK,
    required String provider,
    required String model,
  }) {
    return _aiService.semanticSearch(
      query: query,
      topK: topK,
      provider: provider,
      model: model,
    );
  }
}
