import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'link_extractor.dart';
import '../downloader/download_queue.dart';
import '../../core/models/download_job.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  List<NovelLink> _links  = [];
  bool _loading           = false;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html', 'htm'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() { _loading = true; _fileName = result.files.single.name; });

    final content = await File(result.files.single.path!).readAsString();
    final links   = LinkExtractor.extractFromHtml(content);

    setState(() { _links = links; _loading = false; });

    if (links.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No supported novel links found in that file.')),
        );
      }
    }
  }

  void _queueSelected() {
    final selected = _links.where((l) => l.selected).toList();
    if (selected.isEmpty) return;

    final queue = ref.read(downloadQueueProvider.notifier);
    for (final link in selected) {
      queue.enqueue(DownloadJob()
        ..novelUrl    = link.url
        ..novelTitle  = link.title
        ..platform    = link.platform
        ..status      = JobStatus.queued);
    }

    Navigator.pushNamed(context, '/downloader');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _links.where((l) => l.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from HTML'),
        actions: [
          if (_links.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.select_all),
              label: const Text('All'),
              onPressed: () => setState(() {
                final allSelected = _links.every((l) => l.selected);
                for (final l in _links) { l.selected = !allSelected; }
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          // File picker card
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.4),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.file_open_outlined,
                        size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      _fileName ?? 'Tap to select a saved .html file',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _fileName != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator())),

          if (!_loading && _links.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${_links.length} novels found',
                      style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text('$selectedCount selected',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary)),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _links.length,
                itemBuilder: (_, i) {
                  final link = _links[i];
                  return CheckboxListTile(
                    value:    link.selected,
                    onChanged: (v) => setState(() => link.selected = v ?? false),
                    title: Text(link.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Row(
                      children: [
                        _PlatformChip(link.platform),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(link.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline)),
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],

          if (!_loading && _links.isEmpty && _fileName != null)
            const Expanded(
              child: Center(
                child: Text('No supported links found.\nTry a different file.'),
              ),
            ),
        ],
      ),
      floatingActionButton: selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _queueSelected,
              icon: const Icon(Icons.download_rounded),
              label: Text('Download $selectedCount novel${selectedCount > 1 ? 's' : ''}'),
            )
          : null,
    );
  }
}

class _PlatformChip extends StatelessWidget {
  final String platform;
  const _PlatformChip(this.platform);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(platform,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
    );
  }
}
