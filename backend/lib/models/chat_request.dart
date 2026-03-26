class ChatRequest {
  ChatRequest({
    required this.query,
  });

  final String query;

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      query: (json['query'] ?? '').toString().trim(),
    );
  }
}
