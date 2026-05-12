import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/library/library_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/downloader/downloader_screen.dart';
import '../features/html_parser/checklist_screen.dart';
import 'theme.dart';

class NovelDenApp extends ConsumerWidget {
  const NovelDenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'NovelDen',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      initialRoute: '/',
      routes: {
        '/': (_) => const LibraryScreen(),
        '/reader': (_) => const ReaderScreen(),
        '/downloader': (_) => const DownloaderScreen(),
        '/parse-links': (_) => const ChecklistScreen(),
      },
    );
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
