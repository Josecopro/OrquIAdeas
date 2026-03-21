class SearchRequest {
  SearchRequest({
    required this.query,
    required this.topK,
    required this.provider,
    required this.model,
  });

  final String query;
  final int topK;
  final String provider;
  final String model;

  factory SearchRequest.fromJson(Map<String, dynamic> json) {
    final rawTopK = int.tryParse((json['topK'] ?? '4').toString()) ?? 4;
    final boundedTopK = rawTopK.clamp(1, 10);

    return SearchRequest(
      query: (json['query'] ?? '').toString().trim(),
      topK: boundedTopK,
      provider: (json['provider'] ?? 'ollama').toString(),
      model: (json['model'] ?? '').toString(),
    );
  }
}
