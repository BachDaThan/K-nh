import 'package:flutter/material.dart';
import 'bookshelf_service.dart';
import 'reader_settings.dart';
import 'tts_service.dart';

class TxtReaderScreen extends StatefulWidget {
  final BookEntry book;
  const TxtReaderScreen({super.key, required this.book});

  @override
  State<TxtReaderScreen> createState() => _TxtReaderScreenState();
}

class _TxtReaderScreenState extends State<TxtReaderScreen> {
  String _text = '';
  final _scroll = ScrollController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    await readerSettings.load();
    final c = await bookshelfService.readContent(widget.book);
    setState(() {
      _text = c;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.book.offset > 0 && _scroll.hasClients) {
        final max = _scroll.position.maxScrollExtent;
        final ratio = widget.book.offset / (_text.length.clamp(1, 1 << 30));
        _scroll.jumpTo((max * ratio).clamp(0, max));
      }
    });
  }

  Future<void> _saveProgress() async {
    if (!_scroll.hasClients || _text.isEmpty) return;
    final max = _scroll.position.maxScrollExtent;
    final ratio = max <= 0 ? 0.0 : _scroll.offset / max;
    final off = (ratio * _text.length).round();
    await bookshelfService.updateProgress(widget.book.id, off);
  }

  @override
  void dispose() {
    _saveProgress();
    ttsService.stop();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = readerSettings.backgroundColor;
    final fg = readerSettings.textColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: fg,
        title: Text(widget.book.title, style: TextStyle(color: fg, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              readerSettings.ttsEnabled ? Icons.stop : Icons.record_voice_over,
              color: fg,
            ),
            onPressed: () async {
              if (readerSettings.ttsEnabled) {
                // toggle speaking
                await ttsService.speak(_text);
              } else {
                await ttsService.stop();
              }
            },
            tooltip: 'TTS',
          ),
          IconButton(
            icon: Icon(Icons.text_format, color: fg),
            onPressed: () => _showSettings(context, fg, bg),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification) _saveProgress();
                return false;
              },
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 48),
                child: Text(
                  _text,
                  style: TextStyle(
                    color: fg,
                    fontSize: readerSettings.fontSize,
                    height: readerSettings.lineHeight,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
    );
  }

  void _showSettings(BuildContext context, Color fg, Color bg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Giao diện đọc', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final b in ReaderBg.values)
                      ChoiceChip(
                        label: Text(b.name),
                        selected: readerSettings.bg == b,
                        onSelected: (_) async {
                          readerSettings.bg = b;
                          await readerSettings.save();
                          setS(() {});
                          setState(() {});
                        },
                      ),
                  ],
                ),
                Text('Cỡ chữ ${readerSettings.fontSize.toStringAsFixed(0)}',
                    style: TextStyle(color: fg)),
                Slider(
                  value: readerSettings.fontSize,
                  min: 14,
                  max: 28,
                  onChanged: (v) {
                    setS(() => readerSettings.fontSize = v);
                    setState(() {});
                  },
                  onChangeEnd: (_) => readerSettings.save(),
                ),
                SwitchListTile(
                  title: Text('TTS (đọc thành tiếng)', style: TextStyle(color: fg)),
                  value: readerSettings.ttsEnabled,
                  onChanged: (v) async {
                    readerSettings.ttsEnabled = v;
                    await readerSettings.save();
                    setS(() {});
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
