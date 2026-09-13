import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicTrack {
  final String path;
  final String name;
  MusicTrack(this.path, this.name);

  Map<String, String> toJson() => {'path': path, 'name': name};
  factory MusicTrack.fromJson(Map<String, dynamic> j) =>
      MusicTrack(j['path'] as String, j['name'] as String);
}

/// Nhạc nền MP3 từ máy — volume riêng, lặp playlist / 1 bài.
class MusicPlaylistService {
  final AudioPlayer _player = AudioPlayer();
  final List<MusicTrack> tracks = [];
  int index = 0;
  double volume = 0.35;
  bool loopPlaylist = true;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    volume = p.getDouble('kinh_music_vol') ?? 0.35;
    loopPlaylist = p.getBool('kinh_music_loop') ?? true;
    final raw = p.getStringList('kinh_music_tracks') ?? [];
    tracks
      ..clear()
      ..addAll(raw.map((e) {
        final i = e.indexOf('|');
        if (i < 0) return MusicTrack(e, e.split('/').last);
        return MusicTrack(e.substring(0, i), e.substring(i + 1));
      }));
    await _player.setVolume(volume);
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _onComplete();
      }
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('kinh_music_vol', volume);
    await p.setBool('kinh_music_loop', loopPlaylist);
    await p.setStringList(
      'kinh_music_tracks',
      tracks.map((t) => '${t.path}|${t.name}').toList(),
    );
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    await _player.setVolume(volume);
    await save();
  }

  Future<void> addTracks(List<MusicTrack> list) async {
    tracks.addAll(list);
    await save();
  }

  Future<void> removeAt(int i) async {
    if (i < 0 || i >= tracks.length) return;
    tracks.removeAt(i);
    if (index >= tracks.length) index = 0;
    await save();
  }

  Future<void> move(int from, int to) async {
    if (from < 0 || from >= tracks.length || to < 0 || to >= tracks.length) {
      return;
    }
    final t = tracks.removeAt(from);
    tracks.insert(to, t);
    await save();
  }

  Future<void> playIndex(int i) async {
    if (tracks.isEmpty) return;
    index = i.clamp(0, tracks.length - 1);
    await _player.setFilePath(tracks[index].path);
    await _player.setVolume(volume);
    await _player.play();
  }

  Future<void> play() async {
    if (tracks.isEmpty) return;
    if (_player.audioSource == null) {
      await playIndex(index);
    } else {
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();

  Future<void> _onComplete() async {
    if (tracks.isEmpty) return;
    if (tracks.length == 1 || !loopPlaylist) {
      // 1 bài hoặc không loop playlist → lặp bài hiện tại
      await playIndex(index);
      return;
    }
    index = (index + 1) % tracks.length;
    await playIndex(index);
  }

  void dispose() {
    _player.dispose();
  }
}

final musicPlaylist = MusicPlaylistService();
