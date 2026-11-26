import 'package:flutter/material.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key, required this.initialize, required this.ready});

  final Future<void> Function() initialize;
  final Widget ready;

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  late Future<void> loading = widget.initialize();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: loading,
    builder: (context, state) {
      if (state.connectionState == ConnectionState.done && !state.hasError) {
        return widget.ready;
      }
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFE9F6F3),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book, color: Colors.teal, size: 56),
                const Text('DailyNote', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 20),
                if (state.connectionState != ConnectionState.done)
                  const CircularProgressIndicator()
                else ...[
                  const Text('Gagal menyiapkan aplikasi.'),
                  FilledButton(
                    onPressed: () =>
                        setState(() => loading = widget.initialize()),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
