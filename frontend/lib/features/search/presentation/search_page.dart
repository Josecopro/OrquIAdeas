import 'package:flutter/material.dart';

import '../data/search_repository.dart';
import '../domain/semantic_result.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchRepository _repository = SearchRepository();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _modelController =
      TextEditingController(text: 'llama3');

  bool _loading = false;
  int _topK = 4;
  String _provider = 'ollama';
  SemanticSearchResult? _result;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _loading) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _repository.semanticSearch(
        query: query,
        topK: _topK,
        provider: _provider,
        model: _modelController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = response;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busqueda Semantica RAG'),
        backgroundColor: const Color(0xFF7A4A22),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF8EEDB), Color(0xFFE8F1FF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Consulta tecnica con contexto recuperado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A2D16),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ejemplo: Como fabricar un biofiltro con cascarilla?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'ollama',
                  icon: Icon(Icons.memory_rounded),
                  label: Text('Ollama'),
                ),
                ButtonSegment<String>(
                  value: 'huggingface',
                  icon: Icon(Icons.cloud_done_rounded),
                  label: Text('Hugging Face'),
                ),
              ],
              selected: <String>{_provider},
              onSelectionChanged: (Set<String> value) {
                setState(() {
                  _provider = value.first;
                  if (_provider == 'huggingface' &&
                      _modelController.text.trim() == 'llama3') {
                    _modelController.text =
                        'meta-llama/Meta-Llama-3-8B-Instruct';
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Modelo LLM',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Cantidad de contexto (topK): $_topK'),
            Slider(
              value: _topK.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _topK.toString(),
              onChanged: (double value) {
                setState(() {
                  _topK = value.round();
                });
              },
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _loading ? null : _runSearch,
              icon: _loading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.travel_explore_rounded),
              label: const Text('Ejecutar busqueda RAG'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_result != null) ...<Widget>[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Respuesta generada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF204231),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_result!.answer),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Contextos recuperados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF204231),
                ),
              ),
              const SizedBox(height: 8),
              ..._result!.contexts.map(_ContextCard.new),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard(this.item);

  final SemanticContext item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCC7A1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A3A1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(item.text),
          const SizedBox(height: 8),
          Text(
            'Fuente: ${item.source} | score: ${item.score.toStringAsFixed(3)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
