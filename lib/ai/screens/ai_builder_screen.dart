import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_settings_service.dart';
import '../services/ai_chat_service.dart';
import '../services/snippet_service.dart';

/// Bước 4 — AI Builder & Code Runner
class AiBuilderScreen extends StatefulWidget {
  const AiBuilderScreen({super.key});

  @override
  State<AiBuilderScreen> createState() => _AiBuilderScreenState();
}

class _AiBuilderScreenState extends State<AiBuilderScreen> {
  final _settings = AiSettingsService();
  late final AiChatService _chat;
  final _snippets = SnippetService();

  final _codeCtrl = TextEditingController(
    text:
        '// JavaScript — thử nút Chạy\nconsole.log("Xin chào từ Kính!");\n2 + 2;\n',
  );
  final _promptCtrl = TextEditingController();
  final _outputCtrl = TextEditingController();

  String _language = 'javascript';
  bool _ready = false;
  bool _runnerReady = false;
  bool _running = false;
  bool _aiBusy = false;
  WebViewController? _runner;

  static const _systemCode =
      'Bạn là trợ lý lập trình trong app Kính. Trả lời ngắn. '
      'Khi viết code, ưu tiên code thuần Python hoặc JavaScript.';

  @override
  void initState() {
    super.initState();
    _chat = AiChatService(_settings);
    _init();
  }

  Future<void> _init() async {
    await _settings.load();
    await _snippets.load();
    await _initRunner();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _initRunner() async {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D0D0D))
      ..addJavaScriptChannel(
        'KinhRunner',
        onMessageReceived: (msg) {
          final raw = msg.message;
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            final out = map['out']?.toString() ?? '';
            final ok = map['ok'] == true;
            if (!mounted) return;
            setState(() {
              _running = false;
              if (out.isNotEmpty) {
                _outputCtrl.text = out;
              } else {
                _outputCtrl.text = ok ? '(không có output)' : 'Lỗi (không có chi tiết)';
              }
            });
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _running = false;
              _outputCtrl.text = 'Parse: $e\nRaw: $raw';
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _runnerReady = true);
          },
        ),
      );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final plat = c.platform;
      if (plat is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
      }
    }

    // baseUrl giúp trang có origin HTTPS hợp lệ thay vì null/about:blank —
    // cần thiết để fetch() tới CDN Pyodide không bị chặn bởi CORS/mixed-content.
    final html = await _resolveRunnerHtml();
    c.loadHtmlString(html, baseUrl: 'https://kinh.local/');
    _runner = c;
  }

  static const _hotpatchRunnerHtmlKey = 'kinh_hotpatch_runner_html';

  /// Trả về HTML runner đã được Hot Update vá (nếu có, đã verify chữ ký
  /// Ed25519 từ trước khi lưu — xem HotUpdateService), ngược lại dùng
  /// bản mặc định nhúng cứng trong code.
  Future<String> _resolveRunnerHtml() async {
    try {
      final p = await SharedPreferences.getInstance();
      final patched = p.getString(_hotpatchRunnerHtmlKey);
      if (patched != null && patched.trim().isNotEmpty) return patched;
    } catch (_) {
      // Lỗi đọc SharedPreferences — dùng bản mặc định an toàn.
    }
    return _runnerHtml;
  }

  /// Sandbox HTML: kết quả gửi về Flutter qua KinhRunner.postMessage
  static const _runnerHtml = r'''
<!DOCTYPE html>
<html><head><meta charset="utf-8"/>
<style>
body{margin:0;background:#0d0d0d;color:#aaa;font:12px monospace}
#status{padding:6px 8px;color:#6C8CFF}
</style></head>
<body>
<div id="status">Runner JS sẵn sàng. Python tải khi cần.</div>
<script>
let pyodide = null, pyLoading = null;

async function ensurePy() {
  if (pyodide) return pyodide;
  if (pyLoading) return pyLoading;
  document.getElementById('status').innerText = 'Đang tải Pyodide…';
  pyLoading = (async () => {
    // Lưu ý: loadHtmlString() khiến trang có origin null/about:blank, và
    // một số WebView Android silently fail (không báo onerror) khi chèn
    // <script src="https://..."> động trong ngữ cảnh origin null — biến
    // toàn cục loadPyodide không được gán, gây lỗi
    // "TypeError: loadPyodide is not a function".
    // Sửa: tự fetch() mã nguồn JS rồi eval qua Function() — cách này báo
    // lỗi rõ ràng qua try/catch bình thường thay vì fail âm thầm.
    const PYODIDE_BASE = 'https://cdn.jsdelivr.net/pyodide/v0.26.4/full/';
    let jsCode;
    try {
      const res = await fetch(PYODIDE_BASE + 'pyodide.js');
      if (!res.ok) throw new Error('HTTP ' + res.status);
      jsCode = await res.text();
    } catch (e) {
      throw new Error('Không tải được Pyodide (cần mạng): ' + e.message);
    }
    // Chạy script trong scope toàn cục để loadPyodide được gán vào window.
    (0, eval)(jsCode);
    if (typeof loadPyodide !== 'function') {
      throw new Error('Pyodide script tải xong nhưng loadPyodide vẫn undefined — có thể do phiên bản script thay đổi.');
    }
    pyodide = await loadPyodide({ indexURL: PYODIDE_BASE });
    document.getElementById('status').innerText = 'Pyodide sẵn sàng';
    return pyodide;
  })();
  return pyLoading;
}

async function runJs(code) {
  const logs = [];
  const olog = console.log, oerr = console.error;
  console.log = (...a) => logs.push(a.map(x => typeof x === 'object' ? JSON.stringify(x) : String(x)).join(' '));
  console.error = (...a) => logs.push('[err] ' + a.map(String).join(' '));
  try {
    const result = await eval('(async()=>{\n' + code + '\n})()');
    console.log = olog; console.error = oerr;
    if (result !== undefined) logs.push(String(result));
    return { ok: true, out: logs.join('\n') };
  } catch (e) {
    console.log = olog; console.error = oerr;
    return { ok: false, out: String(e && e.stack ? e.stack : e) };
  }
}

async function runPy(code) {
  try {
    const py = await ensurePy();
    let out = '';
    py.setStdout({ batched: (s) => { out += s + '\n'; } });
    py.setStderr({ batched: (s) => { out += s + '\n'; } });
    await py.runPythonAsync(code);
    return { ok: true, out: out.trimEnd() };
  } catch (e) {
    return { ok: false, out: String(e) };
  }
}

async function runCode(lang, code) {
  let r;
  try {
    r = (lang === 'python') ? await runPy(code) : await runJs(code);
  } catch (e) {
    r = { ok: false, out: String(e) };
  }
  try {
    KinhRunner.postMessage(JSON.stringify(r));
  } catch (e) {
    document.getElementById('status').innerText = 'postMessage fail: ' + e;
  }
}
</script>
</body></html>
''';

  Future<void> _runCode() async {
    final code = _codeCtrl.text;
    if (code.trim().isEmpty || _runner == null) return;
    if (!_runnerReady) {
      setState(() => _outputCtrl.text = 'Runner chưa sẵn sàng — đợi 1–2 giây rồi thử lại.');
      return;
    }
    setState(() {
      _running = true;
      _outputCtrl.text = 'Đang chạy ($_language)…';
    });
    try {
      final escaped = jsonEncode(code);
      final lang = jsonEncode(_language);
      // Không await Promise từ Dart — kết quả về qua channel KinhRunner
      await _runner!.runJavaScript('runCode($lang, $escaped)');
      Future.delayed(const Duration(seconds: 90), () {
        if (mounted && _running) {
          setState(() {
            _running = false;
            if (_outputCtrl.text.startsWith('Đang chạy')) {
              _outputCtrl.text =
                  'Timeout. Python lần đầu cần mạng để tải Pyodide.\nThử lại hoặc chọn JavaScript.';
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _running = false;
        _outputCtrl.text = 'Lỗi runner: $e';
      });
    }
  }

  Future<void> _askAi({required bool applyCode}) async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _aiBusy = true);
    try {
      final user = applyCode
          ? 'Sửa/viết code $_language theo yêu cầu:\n$prompt\n\nCode hiện tại:\n${_codeCtrl.text}'
          : prompt;
      final reply = await _chat.complete(system: _systemCode, user: user);
      if (applyCode) {
        var code = reply;
        final m = RegExp(r'```(?:python|javascript|js)?\n([\s\S]*?)```')
            .firstMatch(reply);
        if (m != null) code = m.group(1)!.trim();
        setState(() {
          _codeCtrl.text = code;
          _outputCtrl.text = 'AI đã cập nhật editor.';
        });
      } else {
        setState(() => _outputCtrl.text = reply);
      }
    } catch (e) {
      setState(() => _outputCtrl.text = 'AI lỗi: $e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _saveSnippet() async {
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController(text: 'Snippet');
        return AlertDialog(
          title: const Text('Lưu snippet'),
          content: TextField(
              controller: c, decoration: const InputDecoration(labelText: 'Tên')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, c.text.trim()),
                child: const Text('Lưu')),
          ],
        );
      },
    );
    if (title == null || title.isEmpty) return;
    await _snippets.upsert(CodeSnippet(
      title: title,
      language: _language,
      code: _codeCtrl.text,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã lưu snippet'),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() {});
    }
  }

  void _openAiSettings() {
    final keyCtrl = TextEditingController(text: _settings.apiKey);
    final baseCtrl = TextEditingController(text: _settings.baseUrl);
    final modelCtrl = TextEditingController(text: _settings.model);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('AI Settings (API key cá nhân)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'OpenAI-compatible: OpenAI, Groq, OpenRouter, LM Studio…',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'API Key', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: baseCtrl,
                decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.openai.com/v1',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'gpt-4o-mini',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await _settings.save(
                    apiKey: keyCtrl.text.trim(),
                    baseUrl: baseCtrl.text.trim(),
                    model: modelCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSnippets() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final items = _snippets.items;
        return SizedBox(
          height: 360,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Snippets', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('Chưa có snippet',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final s = items[i];
                          return ListTile(
                            title: Text(s.title),
                            subtitle: Text(s.language),
                            onTap: () {
                              setState(() {
                                _language = s.language;
                                _codeCtrl.text = s.code;
                              });
                              Navigator.pop(ctx);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await _snippets.remove(s.id);
                                Navigator.pop(ctx);
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _promptCtrl.dispose();
    _outputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('AI Builder'),
        actions: [
          IconButton(icon: const Icon(Icons.folder_open), onPressed: _openSnippets),
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: _saveSnippet),
          IconButton(
            icon: Icon(Icons.settings,
                color: _settings.hasKey ? const Color(0xFF6C8CFF) : Colors.white54),
            onPressed: _openAiSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('JavaScript'),
                  selected: _language == 'javascript',
                  onSelected: (_) => setState(() {
                    _language = 'javascript';
                    if (_codeCtrl.text.contains('print(')) {
                      _codeCtrl.text =
                          'console.log("Hello");\n2 + 2;\n';
                    }
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Python'),
                  selected: _language == 'python',
                  onSelected: (_) => setState(() {
                    _language = 'python';
                    if (_codeCtrl.text.contains('console.log')) {
                      _codeCtrl.text = 'print("Hello")\nprint(2 + 2)\n';
                    }
                  }),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _running || !_runnerReady ? null : _runCode,
                  icon: _running
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow, size: 20),
                  label: Text(_runnerReady ? 'Chạy' : '…'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _codeCtrl,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFFE6E6E6),
                    height: 1.4,
                  ),
                  cursorColor: const Color(0xFF6C8CFF),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: 'Viết code…',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _outputCtrl,
                  maxLines: null,
                  expands: true,
                  readOnly: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFB0B0B0),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: 'Output / AI',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _settings.hasKey
                          ? 'Hỏi AI…'
                          : 'Cần API key (⚙️)',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _askAi(applyCode: false),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: _aiBusy ? null : () => _askAi(applyCode: false),
                  icon: _aiBusy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 18),
                ),
                IconButton.filledTonal(
                  onPressed: _aiBusy ? null : () => _askAi(applyCode: true),
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 1,
            width: 1,
            child: _runner == null
                ? const SizedBox.shrink()
                : WebViewWidget(controller: _runner!),
          ),
        ],
      ),
    );
  }
}
