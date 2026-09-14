import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NoteItem {
  final String id;
  String title;
  String body;
  int updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAt': updatedAt,
      };

  factory NoteItem.fromJson(Map<String, dynamic> j) => NoteItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        updatedAt: j['updatedAt'] as int? ?? 0,
      );
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _key = 'kinh_notes_v1';
  final _uuid = const Uuid();
  List<NoteItem> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? [];
    _notes = raw
        .map((e) {
          try {
            final parts = e.split('\u001e');
            if (parts.length >= 4) {
              return NoteItem(
                id: parts[0],
                title: parts[1],
                body: parts[2],
                updatedAt: int.tryParse(parts[3]) ?? 0,
              );
            }
          } catch (_) {}
          return null;
        })
        .whereType<NoteItem>()
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _key,
      _notes
          .map((n) => '${n.id}\u001e${n.title}\u001e${n.body}\u001e${n.updatedAt}')
          .toList(),
    );
  }

  Future<void> _edit([NoteItem? existing]) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Ghi chú mới' : 'Sửa ghi chú'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Nội dung'),
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing == null) {
      _notes.insert(
        0,
        NoteItem(
          id: _uuid.v4(),
          title: titleCtrl.text.trim().isEmpty ? 'Không tiêu đề' : titleCtrl.text.trim(),
          body: bodyCtrl.text,
          updatedAt: now,
        ),
      );
    } else {
      existing.title =
          titleCtrl.text.trim().isEmpty ? 'Không tiêu đề' : titleCtrl.text.trim();
      existing.body = bodyCtrl.text;
      existing.updatedAt = now;
    }
    await _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi chú')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('Chưa có ghi chú — bấm + để thêm'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (ctx, i) {
                    final n = _notes[i];
                    return ListTile(
                      title: Text(n.title),
                      subtitle: Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _edit(n),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          _notes.removeAt(i);
                          await _save();
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
