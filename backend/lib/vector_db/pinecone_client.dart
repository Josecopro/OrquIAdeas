import 'dart:convert';

import 'package:http/http.dart' as http;

import 'semantic_index_service.dart';

class PineconeUpsertVector {
  PineconeUpsertVector({
    required this.id,
    required this.values,
    required this.metadata,
  });

  final String id;
  final List<double> values;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'values': values,
      'metadata': metadata,
    };
  }
}

class PineconeSemanticIndexService implements SemanticIndexService {
  PineconeSemanticIndexService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> upsertVectors({
    required List<PineconeUpsertVector> vectors,
    int batchSize = 20,
  }) async {
    const apiKey = String.fromEnvironment('PINECONE_API_KEY');
    const host = String.fromEnvironment('PINECONE_INDEX_HOST');
    const namespace = String.fromEnvironment('PINECONE_NAMESPACE');

    if (apiKey.isEmpty || host.isEmpty) {
      throw Exception(
        'PINECONE_API_KEY and PINECONE_INDEX_HOST are required for indexing.',
      );
    }

    if (vectors.isEmpty) {
      return;
    }

    final safeBatchSize = batchSize.clamp(1, 100);

    for (var i = 0; i < vectors.length; i += safeBatchSize) {
      final end = (i + safeBatchSize > vectors.length)
          ? vectors.length
          : i + safeBatchSize;
      final batch = vectors.sublist(i, end);

      final response = await _client.post(
        Uri.parse('https://$host/vectors/upsert'),
        headers: <String, String>{
          'Api-Key': apiKey,
          'Content-Type': 'application/json',
          'X-Pinecone-API-Version': '2024-07',
        },
        body: jsonEncode(<String, dynamic>{
          'vectors':
              batch.map((PineconeUpsertVector item) => item.toJson()).toList(),
          if (namespace.isNotEmpty) 'namespace': namespace,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception('Pinecone upsert error: ${response.body}');
      }
    }
  }

  @override
  Future<List<SemanticDocument>> search({
    required List<double> vector,
    required String query,
    required int topK,
  }) async {
    const apiKey = String.fromEnvironment('PINECONE_API_KEY');
    const host = String.fromEnvironment('PINECONE_INDEX_HOST');
    const namespace = String.fromEnvironment('PINECONE_NAMESPACE');

    if (apiKey.isEmpty || host.isEmpty || vector.isEmpty) {
      return _fallbackDocuments(query, topK);
    }

    final response = await _client.post(
      Uri.parse('https://$host/query'),
      headers: <String, String>{
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
        'X-Pinecone-API-Version': '2024-07',
      },
      body: jsonEncode(<String, dynamic>{
        'vector': vector,
        'topK': topK,
        'includeMetadata': true,
        if (namespace.isNotEmpty) 'namespace': namespace,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Pinecone query error: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final matches = (decoded['matches'] as List<dynamic>?) ?? <dynamic>[];

    return matches.map((dynamic item) {
      final match = item as Map<String, dynamic>;
      final metadata =
          (match['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      return SemanticDocument(
        id: (match['id'] ?? '').toString(),
        score: ((match['score'] ?? 0) as num).toDouble(),
        text: (metadata['text'] ?? metadata['chunk'] ?? '').toString(),
        title: (metadata['title'] ?? 'Documento de contexto').toString(),
        source: (metadata['source'] ?? 'pinecone').toString(),
      );
    }).toList();
  }

  List<SemanticDocument> _fallbackDocuments(String query, int topK) {
    final docs = <SemanticDocument>[
      SemanticDocument(
        id: 'fallback-1',
        score: 0.88,
        title: 'Biochar de cascarilla',
        source: 'fallback-local',
        text:
            'La cascarilla de cafe puede pirolizarse para producir biochar, mejorando la adsorcion de contaminantes organicos en agua.',
      ),
      SemanticDocument(
        id: 'fallback-2',
        score: 0.84,
        title: 'Carbon activado artesanal',
        source: 'fallback-local',
        text:
            'La activacion termica y quimica controlada incrementa area superficial y capacidad de remocion de color, olor y metales.',
      ),
      SemanticDocument(
        id: 'fallback-3',
        score: 0.8,
        title: 'Filtro multicapa rural',
        source: 'fallback-local',
        text:
            'Combinar grava, arena y capa adsorbente de cascarilla tratada mejora la calidad del agua de uso agricola en fincas cafetaleras.',
      ),
      SemanticDocument(
        id: 'fallback-4',
        score: 0.76,
        title: 'Operacion y mantenimiento',
        source: 'fallback-local',
        text:
            'Para conservar rendimiento del filtro, realizar retrolavado y recambio de material adsorbente de forma periodica.',
      ),
    ];

    return docs.take(topK).toList();
  }
}
