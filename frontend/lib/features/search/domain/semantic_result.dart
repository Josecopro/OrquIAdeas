class SemanticContext {
  SemanticContext({
    required this.id,
    required this.title,
    required this.text,
    required this.source,
    required this.score,
  });

  final String id;
  final String title;
  final String text;
  final String source;
  final double score;

  factory SemanticContext.fromJson(Map<String, dynamic> json) {
    return SemanticContext(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      score: ((json['score'] ?? 0) as num).toDouble(),
    );
  }
}

class SemanticSearchResult {
  SemanticSearchResult({
    required this.answer,
    required this.contexts,
  });

  final String answer;
  final List<SemanticContext> contexts;

  factory SemanticSearchResult.fromJson(Map<String, dynamic> json) {
    final rawContexts = (json['contexts'] as List<dynamic>?) ?? <dynamic>[];
    return SemanticSearchResult(
      answer: (json['answer'] ?? '').toString(),
      contexts: rawContexts
          .whereType<Map<String, dynamic>>()
          .map(SemanticContext.fromJson)
          .toList(),
    );
  }
}
