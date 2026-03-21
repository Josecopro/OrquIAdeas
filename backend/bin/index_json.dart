import 'dart:io';

import '../lib/ai/embeddings_client.dart';
import '../lib/indexing/json_indexer.dart';
import '../lib/vector_db/pinecone_client.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/index_json.dart <path-to-file.json> [batchSize]',
    );
    exitCode = 64;
    return;
  }

  final filePath = args.first;
  final batchSize =
      args.length > 1 ? (int.tryParse(args[1]) ?? 20).clamp(1, 100) : 20;

  final indexer = JsonKnowledgeIndexer(
    embeddingsClient: EmbeddingsFactory.create(),
    pineconeService: PineconeSemanticIndexService(),
  );

  try {
    final report = await indexer.indexFile(
      filePath: filePath,
      batchSize: batchSize,
    );

    stdout.writeln('JSON indexing completed.');
    stdout.writeln('File: ${report.filePath}');
    stdout.writeln('Documents read: ${report.documentsRead}');
    stdout.writeln('Documents indexed: ${report.documentsIndexed}');
  } catch (error) {
    stderr.writeln('Indexing failed: $error');
    exitCode = 1;
  }
}
