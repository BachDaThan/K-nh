import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter/foundation.dart';

import '../services/ai_settings_service.dart';
import '../services/ai_chat_service.dart';
import '../services/snippet_service.dart';

/// Bước 4 — AI Builder & Code Runner
/// Editor + chạy Python (Pyodide WASM) / JavaScript trong WebView sandbox.
/// AI dùng API key cá nhân (OpenAI-compatible), 100% client-side.
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
    text: '# Python (Pyodide)\nprint("Xin chào từ Kính!")\nfor i in range(3):\n    print(i)\n',
  );
  final _promptCtrl = TextEditingController();
  final _outputCtrl = TextEditingController();

  String _language = 'python'; // python | javascript
  bool _ready = false;
  bool _runnerReady = false;
  bool _running = false;
  bool _aiBusy = false;
  WebViewController? _runner;

  static const _systemCode = '''
Bạn là trợ lý lập trình trong app Kính.
Trả lời ngắn gọn. Khi viết code, chỉ in code thuần (không markdown) trừ khi user hỏi giải thích.
Ngôn ngữ ưu tiên: Python hoặc JavaScript tùy ngữ cảnh.
''';

  @override
  void initState() {
    super.initState();
    _chat = AiChatService(_settings);
    _init();
  }

  Future<void> _init() async {
    await _settings.load();
    await _snippets.load();
    _initRunner();
    if (mounted) setState(() => _ready = true);
  }

  void _initRunner() {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D0D0D))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _runnerReady = true);
        },
      ));
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final p = c.platform;
      if (p is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
      }
    }
    c.loadHtmlString(_runnerHtml);
    _runner = c;
  }

  /// Sandbox: JS eval ngay; Python qua Pyodide CDN (cần mạng lần đầu).
  static const _runnerHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<style>
  body { margin:0; background:#0d0d0d; color:#c8c8c8; font:12px monospace; }
  #status { padding:6px 8px; color:#6C8CFF; }
</style>
</head>
<body>
<div id="status">Runner sẵn sàng (JS). Python tải khi chạy lần đầu…</div>
<script>
  let pyodide = null;
  let pyLoading = null;

  async function ensurePy() {
    if (pyodide) return pyodide;
    if (pyLoading) return pyLoading;
    document.getElementById('status').innerText = 'Đang tải Pyodide…';
    pyLoading = (async () => {
      const s = document.createElement('script');
      s.src = 'https://cdn.jsdelivr.net/pyodide/v0.26.2/full/pyodide.js';
      document.head.appendChild(s);
      await new Promise((res, rej) => { s.onload = res; s.onerror = rej; });
      pyodide = await loadPyodide();
      document.getElementById('status').innerText = 'Pyodide sẵn sàng';
      return pyodide;
    })();
    return pyLoading;
  }

  async function runJs(code) {
    const logs = [];
    const orig = console.log;
    console.log = (...a) => { logs.push(a.map(String).join(' ')); };
    try {
      const result = await eval('(async()=>{\\n' + code + '\\n})()');
      console.log = orig;
      if (result !== undefined) logs.push(String(result));
      return { ok: true, out: logs.join('\\n') };
    } catch (e) {
      console.log = orig;
      return { ok: false, out: String(e) };
    }
  }

  async function runPy(code) {
    try {
      const py = await ensurePy();
      let out = '';
      py.setStdout({ batched: (s) => { out += s + '\\n'; } });
      py.setStderr({ batched: (s) => { out += s + '\\n'; } });
      await py.runPythonAsync(code);
      return { ok: true, out: out.trimEnd() };
    } catch (e) {
      return { ok: false, out: String(e) };
    }
  }

  async function runCode(lang, code) {
    if (lang === 'python') return runPy(code);
    return runJs(code);
  }
</script>
</body>
</html>
''';

  Future<void> _runCode() async {
    final code = _codeCtrl.text;
    if (code.trim().isEmpty || _runner == null) return;
    setState(() {
      _running = true;
      _outputCtrl.text = 'Đang chạy ($_language)…';
    });
    try {
      final escaped = jsonEncode(code);
      final lang = jsonEncode(_language);
      final raw = await _runner!.runJavaScriptReturningResult(
        'runCode($lang, $escaped).then(r => JSON.stringify(r))',
      );
      var s = raw?.toString() ?? '{}';
      // WebView sometimes wraps result in quotes
      if (s.startsWith('"') && s.endsWith('"')) {
        s = jsonDecode(s) as String;
      }
      final map = jsonDecode(s) as Map<String, dynamic>;
      final out = map['out']?.toString() ?? '';
      final ok = map['ok'] == true;
      setState(() {
        _outputCtrl.text = out.isEmpty
            ? (ok ? '(không có output)' : 'Lỗi không rõ')
            : out;
      });
    } catch (e) {
      setState(() => _outputCtrl.text = 'Lỗi runner: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _askAi({bool applyCode = false}) async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _aiBusy = true);
    try {
      final user = applyCode
          ? 'Sửa/viết code $_language theo yêu cầu:\n$prompt\n\nCode hiện tại:\n${_codeCtrl.text}'
          : prompt;
      final reply = await _chat.complete(
        system: _systemCode,
        user: user,
      );
      if (applyCode) {
        // Lấy code nếu AI bọc ``` 
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
          content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Tên')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Lưu')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu snippet'), behavior: SnackBarBehavior.floating),
      );
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
                'Lưu trên máy. Dùng endpoint OpenAI-compatible (OpenAI, Groq, OpenRouter, LM Studio…).',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: baseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.openai.com/v1',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'gpt-4o-mini',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
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
                child: Text('Snippets đã lưu',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Chưa có snippet', style: TextStyle(color: Colors.white54)))
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
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Snippets',
            onPressed: _openSnippets,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Lưu snippet',
            onPressed: _saveSnippet,
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: _settings.hasKey ? const Color(0xFF6C8CFF) : Colors.white54,
            ),
            tooltip: 'AI Settings',
            onPressed: _openAiSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Language + run
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Python'),
                  selected: _language == 'python',
                  onSelected: (_) => setState(() {
                    _language = 'python';
                    if (_codeCtrl.text.contains('console.log')) {
                      _codeCtrl.text =
                          '# Python\nprint("Hello")\n';
                    }
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('JavaScript'),
                  selected: _language == 'javascript',
                  onSelected: (_) => setState(() {
                    _language = 'javascript';
                    if (_codeCtrl.text.contains('print(')) {
                      _codeCtrl.text =
                          '// JavaScript\nconsole.log("Hello");\n';
                    }
                  }),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _running || !_runnerReady ? null : _runCode,
                  icon: _running
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Chạy'),
                ),
              ],
            ),
          ),
          // Editor
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
                    hintText: 'Viết code tại đây…',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Output
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
                    hintText: 'Output / AI response',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
          // AI prompt bar
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
                          ? 'Hỏi AI hoặc mô tả code cần viết…'
                          : 'Cần API key (⚙️) để dùng AI',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
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
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 18),
                  tooltip: 'Hỏi AI',
                ),
                IconButton.filledTonal(
                  onPressed: _aiBusy ? null : () => _askAi(applyCode: true),
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  tooltip: 'AI viết/sửa code vào editor',
                ),
              ],
            ),
          ),
          // Hidden runner webview
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
