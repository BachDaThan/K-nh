import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../reader/tts_service.dart';
import 'music_playlist_service.dart';
import 'story_fetcher.dart';
import 'vbook_catalog.dart';

/// Audio truyện: dán link → lấy text → TTS + auto chương sau + nhạc nền.
/// Giọng máy offline (free). Không phải plugin vBook zip đầy đủ.
class StoryAudioScreen extends StatefulWidget {
  const StoryAudioScreen({super.key});

  @override
  State<StoryAudioScreen> createState() => _StoryAudioScreenState();
}

class _StoryAudioScreenState extends State<StoryAudioScreen> {
  final _urlCtrl = TextEditingController();
  String _status = 'Dán link chương truyện rồi bấm Phát.';
  String? _title;
  bool _busy = false;
  bool _playing = false;
  bool _autoNext = true;
  List<Map<String, String>> _voices = [];
  String? _voiceName;
  String? _voiceLocale;
  List<VbookPlugin> _catalog = [];
  double _ttsVol = 1.0;
  double _musicVol = 0.35;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await musicPlaylist.load();
    _musicVol = musicPlaylist.volume;
    final voices = await ttsService.listVoices();
    setState(() {
      _voices = voices;
      if (voices.isNotEmpty) {
        final vi = voices.firstWhere(
          (v) => (v['locale'] ?? '').toLowerCase().contains('vi'),
          orElse: () => voices.first,
        );
        _voiceName = vi['name'];
        _voiceLocale = vi['locale'];
      }
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    ttsService.stop();
    super.dispose();
  }

  Future<void> _playUrl(String url) async {
    if (url.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _status = 'Đang tải chương…';
      _playing = true;
    });
    try {
      await ttsService.setVoiceByName(_voiceName, locale: _voiceLocale);
      await ttsService.setVolume(_ttsVol);
      final ch = await StoryFetcher.fetch(url.trim());
      setState(() {
        _title = ch.title;
        _status = 'Đang đọc: ${ch.title}';
        _urlCtrl.text = ch.url;
      });
      ttsService.onComplete = () async {
        if (!_autoNext || !_playing) {
          setState(() => _playing = false);
          return;
        }
        if (ch.nextUrl == null) {
          setState(() {
            _playing = false;
            _status = 'Hết link chương sau.';
          });
          return;
        }
        await _playUrl(ch.nextUrl!);
      };
      await ttsService.speakLong(ch.content);
    } catch (e) {
      setState(() {
        _status = 'Lỗi: $e';
        _playing = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopAll() async {
    _playing = false;
    ttsService.onComplete = null;
    await ttsService.stop();
    await musicPlaylist.pause();
    setState(() => _status = 'Đã dừng.');
  }

  Future<void> _addMusic() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'wav', 'ogg'],
      allowMultiple: true,
    );
    if (r == null || r.files.isEmpty) return;
    final list = <MusicTrack>[];
    for (final f in r.files) {
      if (f.path == null) continue;
      list.add(MusicTrack(f.path!, f.name));
    }
    await musicPlaylist.addTracks(list);
    setState(() {});
  }

  Future<void> _loadCatalog() async {
    setState(() => _status = 'Tải catalog vBook…');
    try {
      final c = await VbookCatalog.load();
      setState(() {
        _catalog = c;
        _status = 'Catalog: ${c.length} nguồn (mở site, không chạy plugin zip).';
      });
    } catch (e) {
      setState(() => _status = 'Catalog lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio truyện'),
        actions: [
          IconButton(
            tooltip: 'Dừng',
            onPressed: _stopAll,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Giọng máy offline · free · không API key.\n'
            'Khóa màn hình: cố gắng giữ TTS (wakelock + audio). '
            'Android có thể cần tắt tối ưu pin cho app Kính.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Link chương truyện',
              border: OutlineInputBorder(),
              hintText: 'https://…',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _playUrl(_urlCtrl.text.trim()),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_busy ? 'Đang chạy…' : 'Phát audio'),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Tự chương sau'),
                selected: _autoNext,
                onSelected: (v) => setState(() => _autoNext = v),
              ),
            ],
          ),
          if (_title != null) ...[
            const SizedBox(height: 8),
            Text(_title!, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 6),
          Text(_status, style: const TextStyle(fontSize: 13)),
          const Divider(height: 28),
          const Text('Giọng đọc (máy)', style: TextStyle(fontWeight: FontWeight.w600)),
          DropdownButtonFormField<String>(
            value: _voiceName,
            isExpanded: true,
            items: _voices
                .map(
                  (v) => DropdownMenuItem(
                    value: v['name'],
                    child: Text(
                      '${v['name']} (${v['locale']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (name) {
              final v = _voices.firstWhere((e) => e['name'] == name);
              setState(() {
                _voiceName = name;
                _voiceLocale = v['locale'];
              });
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Text('Âm lượng truyện: ${(_ttsVol * 100).round()}%'),
          Slider(
            value: _ttsVol,
            onChanged: (v) async {
              setState(() => _ttsVol = v);
              await ttsService.setVolume(v);
            },
          ),
          Text('Âm lượng nhạc: ${(_musicVol * 100).round()}%'),
          Slider(
            value: _musicVol,
            onChanged: (v) async {
              setState(() => _musicVol = v);
              await musicPlaylist.setVolume(v);
            },
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Text('Nhạc nền MP3',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: _addMusic,
                icon: const Icon(Icons.playlist_add),
                tooltip: 'Thêm file',
              ),
              IconButton(
                onPressed: () => musicPlaylist.play(),
                icon: const Icon(Icons.music_note),
                tooltip: 'Phát nhạc',
              ),
              IconButton(
                onPressed: () => musicPlaylist.pause(),
                icon: const Icon(Icons.pause),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lặp cả danh sách (hết → đầu)'),
            subtitle: const Text('Tắt / 1 bài: lặp bài hiện tại'),
            value: musicPlaylist.loopPlaylist,
            onChanged: (v) async {
              musicPlaylist.loopPlaylist = v;
              await musicPlaylist.save();
              setState(() {});
            },
          ),
          if (musicPlaylist.tracks.isEmpty)
            const Text('Chưa có bài — bấm + để chọn MP3 trên máy.')
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: musicPlaylist.tracks.length,
              onReorder: (a, b) async {
                var to = b;
                if (to > a) to -= 1;
                await musicPlaylist.move(a, to);
                setState(() {});
              },
              itemBuilder: (ctx, i) {
                final t = musicPlaylist.tracks[i];
                return ListTile(
                  key: ValueKey(t.path),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => musicPlaylist.playIndex(i),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await musicPlaylist.removeAt(i);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          const Divider(height: 28),
          Row(
            children: [
              const Text('Catalog vBook',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(onPressed: _loadCatalog, child: const Text('Tải list')),
            ],
          ),
          Text(
            'https://www.vbookext.me/api/plugin.json — chỉ danh sách nguồn. '
            'Không chạy file plugin.zip như app vBook.',
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
          ),
          ..._catalog.take(40).map(
                (p) => ListTile(
                  dense: true,
                  title: Text(p.name),
                  subtitle: Text(p.source, maxLines: 1),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    final u = Uri.tryParse(p.source);
                    if (u != null) {
                      await launchUrl(u, mode: LaunchMode.externalApplication);
                    }
                    _urlCtrl.text = p.source;
                  },
                ),
              ),
        ],
      ),
    );
  }
}
