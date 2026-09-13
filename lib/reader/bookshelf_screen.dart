import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'bookshelf_service.dart';
import 'txt_reader_screen.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  @override
  void initState() {
    super.initState();
    bookshelfService.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _import() async {
    // file_picker ≥11: không còn FilePicker.platform — dùng static pickFiles
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt'],
      allowMultiple: false,
    );
    if (result == null) return;

    // v11: FilePickerResult; một số bản trả files qua .files
    final files = result.files;
    if (files.isEmpty) return;
    final f = files.first;

    String? path = f.path;
    // Windows/Android: path thường có; nếu null thì ghi tạm từ bytes
    if (path == null || path.isEmpty) {
      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không đọc được file')),
          );
        }
        return;
      }
      final dir = Directory.systemTemp;
      final tmp = File('${dir.path}/kinh_import_${f.name}');
      await tmp.writeAsBytes(bytes, flush: true);
      path = tmp.path;
    }

    await bookshelfService.importTxtFile(path, f.name);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tủ sách (TXT)'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _import),
        ],
      ),
      body: bookshelfService.books.isEmpty
          ? const Center(
              child: Text('Chưa có sách — bấm + để thêm file .txt'),
            )
          : ListView.builder(
              itemCount: bookshelfService.books.length,
              itemBuilder: (ctx, i) {
                final b = bookshelfService.books[i];
                return ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(b.title),
                  subtitle: Text('Tiến độ ký tự: ${b.offset}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TxtReaderScreen(book: b),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await bookshelfService.remove(b.id);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}
