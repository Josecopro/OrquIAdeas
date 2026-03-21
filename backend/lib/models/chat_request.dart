class ChatRequest {
  ChatRequest({
    required this.query,
    required this.provider,
    required this.model,
  });

  final String query;
  final String provider;
  final String model;

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      query: (json['query'] ?? '').toString().trim(),
      provider: (json['provider'] ?? 'ollama').toString(),
      model: (json['model'] ?? '').toString(),
    );
  }
}
