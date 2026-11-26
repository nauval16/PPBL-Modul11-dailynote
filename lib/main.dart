import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';
import 'notes_page.dart';
import 'startup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_KEY');

  if (url.isEmpty || key.isEmpty) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Isi URL dan key melalui dart-define.')),
        ),
      ),
    );
    return;
  }

  runApp(
    StartupPage(
      initialize: () async {
        await Supabase.initialize(url: url, publishableKey: key);
      },
      ready: const DailyNoteApp(),
    ),
  );
}

class DailyNoteApp extends StatefulWidget {
  const DailyNoteApp({super.key});

  @override
  State<DailyNoteApp> createState() => _DailyNoteAppState();
}

class _DailyNoteAppState extends State<DailyNoteApp> {
  final auth = Supabase.instance.client.auth;
  late final events = auth.onAuthStateChange;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyNote',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: StreamBuilder<AuthState>(
        stream: events,
        builder: (context, snapshot) {
          final user = auth.currentSession?.user;
          if (user == null) return const AuthPage();
          return NotesPage(key: ValueKey(user.id));
        },
      ),
    );
  }
}
