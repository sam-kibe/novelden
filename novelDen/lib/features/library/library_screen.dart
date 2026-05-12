import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NovelDen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open_outlined),
            tooltip: 'Import from HTML',
            onPressed: () => Navigator.pushNamed(context, '/parse-links'),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Downloads',
            onPressed: () => Navigator.pushNamed(context, '/downloader'),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Your library is empty',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap the folder icon to import novels',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
