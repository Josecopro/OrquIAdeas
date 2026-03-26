import 'package:flutter/material.dart';

import 'features/chat/presentation/chat_page.dart';

void main() {
  runApp(const CafiWaterApp());
}

class CafiWaterApp extends StatelessWidget {
  const CafiWaterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CafiWater AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B6F4C),
          primary: const Color(0xFF2B6F4C),
          secondary: const Color(0xFFCB8C44),
          surface: const Color(0xFFF8F5EF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F5EF),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ChatPage());
  }
}
