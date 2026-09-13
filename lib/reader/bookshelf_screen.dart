import 'package:file_picker/file_picker.dart';
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
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (r == null || r.files.isEmpty) return;
    final f = r.files.single;
    if (f.path == null) return;
    await bookshelfService.importTxtFile(f.path!, f.name);
    setState(() {});
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
