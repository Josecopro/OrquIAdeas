import 'package:flutter/material.dart';

import '../data/chat_repository.dart';
import '../domain/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatRepository _repository = ChatRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = <ChatMessage>[
    ChatMessage(
      author: Author.assistant,
      text:
          'Hola, soy CafiWater AI. Te ayudo a transformar cascarilla de cafe en soluciones para purificacion de agua.',
      timestamp: DateTime.now(),
    ),
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(
        ChatMessage(
          author: Author.user,
          text: query,
          timestamp: DateTime.now(),
        ),
      );
      _controller.clear();
    });

    _scrollToBottom();

    try {
      debugPrint('[chat-ui] Sending message to backend (/chat)...');
      final answer = await _repository.askAssistant(query);
      debugPrint('[chat-ui] Backend connection OK, response received.');
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          ChatMessage(
            author: Author.assistant,
            text: answer,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (error, stackTrace) {
      debugPrint('[chat-ui] Backend/Gemini request failed: $error');
      debugPrint('[chat-ui] Stack: $stackTrace');
      if (!mounted) {
        return;
      }

      final details = error.toString();
      setState(() {
        _messages.add(
          ChatMessage(
            author: Author.assistant,
            text:
                'No pude completar la consulta. Detalle: $details\n\nVerifica backend activo, GEMINI_API_KEY y cuota de Gemini.',
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CafiWater AI'),
        backgroundColor: const Color(0xFF2B6F4C),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF4EFE4), Color(0xFFE7F1EA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _HeroHeader(theme: theme),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final message = _messages[index];
                    final isUser = message.author == Author.user;
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF2B6F4C)
                              : const Color.fromRGBO(255, 255, 255, 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color:
                                isUser ? Colors.white : const Color(0xFF1B1B1B),
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _Composer(
                controller: _controller,
                isSending: _isSending,
                onSend: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Asistente tecnico para cascarilla de cafe',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF184734),
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _TopicChip(text: 'Biofiltros de bajo costo'),
              _TopicChip(text: 'Carbon activado artesanal'),
              _TopicChip(text: 'Riego y reutilizacion de agua'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCB8C44), width: 1.2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF5D3B1F),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Pregunta sobre cascarilla de cafe y purificacion...',
                filled: true,
                fillColor: const Color(0xFFF2F5F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2B6F4C),
              fixedSize: const Size(52, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isSending ? null : onSend,
            child: isSending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
