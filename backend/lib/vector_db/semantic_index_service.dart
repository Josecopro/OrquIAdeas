class SemanticDocument {
  SemanticDocument({
    required this.id,
    required this.score,
    required this.text,
    required this.title,
    required this.source,
  });

  final String id;
  final double score;
  final String text;
  final String title;
  final String source;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'score': score,
      'text': text,
      'title': title,
      'source': source,
    };
  }
}

abstract class SemanticIndexService {
  Future<List<SemanticDocument>> search({
    required List<double> vector,
    required String query,
    required int topK,
  });
}
