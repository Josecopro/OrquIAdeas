import 'dart:convert';
import 'dart:io';

import '../ai/embeddings_client.dart';
import '../vector_db/pinecone_client.dart';

class JsonIndexerReport {
  JsonIndexerReport({
    required this.filePath,
    required this.documentsRead,
    required this.documentsIndexed,
  });

  final String filePath;
  final int documentsRead;
  final int documentsIndexed;
}

class JsonKnowledgeIndexer {
  JsonKnowledgeIndexer({
    required EmbeddingsClient embeddingsClient,
    required PineconeSemanticIndexService pineconeService,
  })  : _embeddingsClient = embeddingsClient,
        _pineconeService = pineconeService;

  final EmbeddingsClient _embeddingsClient;
  final PineconeSemanticIndexService _pineconeService;

  Future<JsonIndexerReport> indexFile({
    required String filePath,
    int batchSize = 20,
  }) async {
    if (!filePath.toLowerCase().endsWith('.json')) {
      throw Exception('Only .json files are supported by this indexer.');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    final documents = _parseDocuments(decoded);

    if (documents.isEmpty) {
      throw Exception('No valid documents found in JSON file.');
    }

    final vectors = <PineconeUpsertVector>[];
    for (final item in documents) {
      if (item.text.trim().isEmpty) {
        continue;
      }

      final embedding = await _embeddingsClient.embed(item.text);
      if (embedding.isEmpty) {
        continue;
      }

      vectors.add(
        PineconeUpsertVector(
          id: item.id,
          values: embedding,
          metadata: <String, dynamic>{
            'title': item.title,
            'text': item.text,
            'source': item.source,
          },
        ),
      );
    }

    if (vectors.isEmpty) {
      throw Exception('No vectors generated from JSON content.');
    }

    await _pineconeService.upsertVectors(
        vectors: vectors, batchSize: batchSize);

    return JsonIndexerReport(
      filePath: filePath,
      documentsRead: documents.length,
      documentsIndexed: vectors.length,
    );
  }

  List<_JsonDoc> _parseDocuments(dynamic jsonData) {
    if (jsonData is List<dynamic>) {
      return _mapRows(jsonData);
    }

    if (jsonData is Map<String, dynamic>) {
      final docs = jsonData['documents'];
      if (docs is List<dynamic>) {
        return _mapRows(docs);
      }
    }

    throw Exception(
      'Invalid JSON format. Use an array of documents or {"documents": [...]}',
    );
  }

  List<_JsonDoc> _mapRows(List<dynamic> rows) {
    final result = <_JsonDoc>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is! Map<String, dynamic>) {
        continue;
      }

      final text = (row['text'] ?? row['chunk'] ?? '').toString();
      final title = (row['title'] ?? 'Documento ${i + 1}').toString();
      final source = (row['source'] ?? 'json').toString();
      final id = (row['id'] ?? 'json-${i + 1}').toString();

      result.add(
        _JsonDoc(
          id: id,
          title: title,
          source: source,
          text: text,
        ),
      );
    }

    return result;
  }
}

class _JsonDoc {
  _JsonDoc({
    required this.id,
    required this.title,
    required this.source,
    required this.text,
  });

  final String id;
  final String title;
  final String source;
  final String text;
}
