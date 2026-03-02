import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sqlite_notes_demo/data/repositories/note_repository.dart';
import 'package:flutter_sqlite_notes_demo/ui/home_page.dart';
import 'package:flutter_sqlite_notes_demo/ui/state/note_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NoteRepository>(create: (_) => NoteRepository()),
        ChangeNotifierProvider<NoteStore>(
          create: (context) => NoteStore(context.read<NoteRepository>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter + SQLite Notes',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
