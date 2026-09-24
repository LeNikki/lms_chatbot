import 'package:flutter/material.dart';
import 'package:lms_chatbot/core/models/upload_metadata.dart';
import 'package:stacked_services/stacked_services.dart';

class UploadDetailsDialog extends StatefulWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const UploadDetailsDialog({
    Key? key,
    required this.request,
    required this.completer,
  }) : super(key: key);

  @override
  State<UploadDetailsDialog> createState() => _UploadDetailsDialogState();
}

class _UploadDetailsDialogState extends State<UploadDetailsDialog> {
  late final List<UploadFileMetadata> _files =
      List<UploadFileMetadata>.from(widget.request.data as List);
  late final List<TextEditingController> _titleControllers = _files
      .map((f) => TextEditingController(text: f.title))
      .toList();
  late final List<TextEditingController> _authorControllers = _files
      .map((f) => TextEditingController(text: f.author))
      .toList();

  @override
  void dispose() {
    for (final c in _titleControllers) {
      c.dispose();
    }
    for (final c in _authorControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    for (int i = 0; i < _files.length; i++) {
      _files[i].title = _titleControllers[i].text.trim();
      _files[i].author = _authorControllers[i].text.trim();
    }

    widget.completer(DialogResponse(
      confirmed: true,
      data: _files,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.request.title ?? 'File Details',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.request.description ?? 'Edit the title and author for each file before uploading.',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _files[index].fileName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _authorControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Author',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        widget.completer(DialogResponse(confirmed: false)),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Upload'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}