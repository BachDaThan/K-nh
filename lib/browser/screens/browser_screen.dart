import 'package:flutter/material.dart';
import '../services/adblock_service.dart';
import '../services/search_engine_service.dart';
import '../engine/browser_engine.dart';
import '../engine/chromium_browser_engine.dart';
import '../models/browser_tab.dart';
import '../models/bookmark.dart';
import '../models/download_item.dart';
import '../services/bookmark_service.dart';
import '../services/doh_service.dart';
import '../services/download_service.dart';
import '../services/password_service.dart';
import '../services/search_diversity.dart';
import '../widgets/omnibox.dart';
import '../widgets/tab_strip.dart';
import '../widgets/bookmark_bar.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/history_sheet.dart';
import '../widgets/activity_log_sheet.dart';
import '../widgets/privacy_sheet.dart';
import '../services/history_service.dart';
import '../services/activity_log_service.dart';
import '../models/activity_event.dart';

/// Màn hình trình duyệt chính của Kính (Bước 2).
///
/// Tất cả thao tác web đều đi qua [BrowserEngine] — không gọi thẳng
/// flutter_inappwebview ở đây.
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final ChromiumBrowserEngine _engine;
  final List<BrowserTab> _tabs = [];
  String? _activeTabId;
  bool _findVisible = false;
  final _findCtrl = TextEditingController();

  final _bookmarkService = BookmarkService();
  final _dohService = DohService();
  final _downloadService = DownloadService();
  final _passwordService = PasswordService();
  final _diversityService = SearchDiversityService();
  final _historyService = HistoryService();
  final _activityLog = ActivityLogService();

  final _omniboxController = TextEditingController();
  bool _servicesReady = false;

  /// URL gốc khi tab được tạo (vd. google.com). Back ở trang này → về Dashboard.
  final Map<String, String> _tabRootUrl = {};
  /// User đã điều hướng ra khỏi trang chủ tab chưa.
  final Map<String, bool> _tabLeftRoot = {};

  @override
  void initState() {
    super.initState();
    _engine = ChromiumBrowserEngine();
    _wireEngineCallbacks();
    _initServicesAndFirstTab();
    adblockService.load();
    searchEngineService.onEngineChanged = (engine) {
      final id = _activeTabId;
      if (id != null) {
        _loadInTab(id, engine.homeUrl);
      }
    };
  }

  void _wireEngineCallbacks() {
    _engine.onTitleChanged = (tabId, title) {
      final t = _findTab(tabId);
      if (t != null && mounted) {
        setState(() => t.title = title ?? t.title);
      }
    };
    _engine.onUrlChanged = (tabId, url) {
      final tab = _findTab(tabId);
      if (tab != null && mounted) {
        final u = url ?? tab.url;
        setState(() {
          tab.url = u;
          if (tabId == _activeTabId) {
            _omniboxController.text = u == 'about:blank' ? '' : u;
          }
        });
        // Không đánh dấu leftRoot ở đây — redirect Google/consent làm false positive.
        // Chỉ Omnibox / Bookmark mới coi là user chủ động đi trang khác.
      }
    };
    _engine.onProgressChanged = (tabId, progress) {
      final t = _findTab(tabId);
      if (t != null && mounted) setState(() => t.progress = progress);
    };
    _engine.onLoadingChanged = (tabId, loading) {
      final tab = _findTab(tabId);
      if (tab != null && mounted) setState(() => tab.isLoading = loading);
      // Khi load xong: ghi lịch sử (nếu không ẩn danh)
      if (!loading && tab != null && !tab.isIncognito) {
        final u = tab.url;
        if (u.isNotEmpty && u != 'about:blank') {
          _historyService.add(title: tab.title, url: u);
          _activityLog.log(
            kind: ActivityKind.pageFinished,
            message: 'Tải xong: ${tab.title.isEmpty ? u : tab.title}',
            url: u,
          );
        }
      }
    };
    _engine.onNavStateChanged = (tabId, back, forward) {
      final t = _findTab(tabId);
      if (t != null && mounted) {
        setState(() {
          t.canGoBack = back;
          t.canGoForward = forward;
        });
      }
    };
    _engine.onDownloadStart = (tabId, url, fileName) {
      _downloadService.enqueue(url, fileName).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bắt đầu tải: $fileName'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Xem',
                onPressed: () => _openDownloadsSheet(),
              ),
            ),
          );
          setState(() {});
        }
      });
    };
  }

  Future<void> _initServicesAndFirstTab() async {
    await Future.wait([
      _bookmarkService.load(),
      _dohService.load(),
      _downloadService.load(),
      _passwordService.load(),
      _diversityService.load(),
      _historyService.load(),
      _activityLog.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _servicesReady = true;
      _addTab(activate: true);
    });
  }

  BrowserTab? _findTab(String id) {
    try {
      return _tabs.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  BrowserTab? get _activeTab =>
      _activeTabId == null ? null : _findTab(_activeTabId!);

  void _addTab({bool activate = true, String? initialUrl, bool incognito = false}) {
    final tab = BrowserTab(
      isIncognito: incognito,
      title: incognito ? 'Ẩn danh' : 'Tab mới',
    );
    _engine.ensureController(tab.id);
    setState(() {
      _tabs.add(tab);
      if (activate) {
        _activeTabId = tab.id;
        _omniboxController.text = '';
      }
    });
    // Mặc định mở trang chủ nếu không có URL — giúp WebView mount + load thật
    final url = (initialUrl != null && initialUrl.isNotEmpty)
        ? initialUrl
        : searchEngineService.current.homeUrl;
    _tabRootUrl[tab.id] = url;
    _tabLeftRoot[tab.id] = false;
    if (incognito) {
      _activityLog.log(
        kind: ActivityKind.incognitoStart,
        message: 'Mở tab ẩn danh',
        ephemeral: true,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInTab(tab.id, url);
      if (activate) {
        _omniboxController.text = url;
      }
    });
  }

  void _closeTab(String id) {
    final idx = _tabs.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    _engine.disposeTab(id);
    _tabRootUrl.remove(id);
    _tabLeftRoot.remove(id);
    setState(() {
      _tabs.removeAt(idx);
      if (_tabs.isEmpty) {
        _addTab(activate: true);
      } else if (_activeTabId == id) {
        final newIdx = idx.clamp(0, _tabs.length - 1);
        _activeTabId = _tabs[newIdx].id;
        _omniboxController.text =
            _tabs[newIdx].url == 'about:blank' ? '' : _tabs[newIdx].url;
      }
    });
  }

  void _switchTab(String id) {
    final t = _findTab(id);
    if (t == null) return;
    setState(() {
      _activeTabId = id;
      t.lastAccessed = DateTime.now();
      _omniboxController.text = t.url == 'about:blank' ? '' : t.url;
    });
  }


  void _toggleFind() {
    setState(() => _findVisible = !_findVisible);
    if (!_findVisible) {
      final id = _activeTabId;
      if (id != null) {
        _engine.evaluateJavascript(
          id,
          "try { window.getSelection().removeAllRanges(); } catch(e) {}",
        );
      }
    }
  }

  Future<void> _runFind({bool forward = true}) async {
    final id = _activeTabId;
    if (id == null) return;
    final q = _findCtrl.text
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'");
    final back = forward ? 'false' : 'true';
    await _engine.evaluateJavascript(
      id,
      "(function(){ try { return window.find('$q', false, $back, true, false, false, false); } catch(e) { return false; } })()",
    );
  }

  Future<void> _runReader() async {
    final id = _activeTabId;
    if (id == null) return;
    const js = r'''(function(){
  if (document.getElementById('kinh-reader-root')) return;
  var article = document.querySelector('article') || document.querySelector('[role=main]') || document.body;
  var title = document.title || '';
  var paras = Array.from(article.querySelectorAll('p, h1, h2, h3, li'))
    .map(function(el){ return el.innerText.trim(); })
    .filter(function(t){ return t.length > 40; })
    .slice(0, 80);
  if (paras.length < 2) {
    paras = [article.innerText.slice(0, 12000)];
  }
  var root = document.createElement('div');
  root.id = 'kinh-reader-root';
  root.setAttribute('style',
    'position:fixed;inset:0;z-index:2147483647;overflow:auto;' +
    'background:#121212;color:#e8e8e8;padding:24px 18px 48px;' +
    'font:18px/1.65 Georgia,serif;');
  var h = document.createElement('h1');
  h.textContent = title;
  h.style.cssText = 'font-size:1.4rem;margin:0 0 12px;color:#fff;';
  root.appendChild(h);
  var bar = document.createElement('button');
  bar.textContent = 'Dong Reader';
  bar.style.cssText = 'margin-bottom:16px;padding:8px 12px;border-radius:8px;border:0;background:#6C8CFF;color:#fff;';
  bar.onclick = function(){ root.remove(); };
  root.appendChild(bar);
  paras.forEach(function(t){
    var p = document.createElement('p');
    p.textContent = t;
    p.style.margin = '0 0 1em';
    root.appendChild(p);
  });
  document.documentElement.appendChild(root);
})();''';
    await _engine.evaluateJavascript(id, js);
  }

  Future<void> _loadInTab(String tabId, String raw) async {
    final tab = _findTab(tabId);
    final looksLikeUrl =
        raw.contains('://') || (raw.contains('.') && !raw.contains(' '));
    final query = looksLikeUrl ? raw : _diversityService.transformQuery(raw);
    final ephemeral = tab?.isIncognito == true;
    await _activityLog.log(
      kind: ActivityKind.navigation,
      message: 'Điều hướng: $query',
      url: query,
      ephemeral: ephemeral,
    );
    await _engine.loadUrl(tabId, query);
  }

  Future<void> _onOmniboxSubmit(String value) async {
    final tab = _activeTab;
    if (tab == null || value.trim().isEmpty) return;
    final raw = value.trim();
    // User chủ động gõ URL/tìm kiếm → coi như đã rời trang chủ tab
    final root = _tabRootUrl[tab.id];
    if (root == null || !_sameSite(root, raw)) {
      _tabLeftRoot[tab.id] = true;
    }
    await _loadInTab(tab.id, raw);
  }

  Future<void> _toggleBookmark() async {
    final tab = _activeTab;
    if (tab == null || tab.url == 'about:blank') return;
    if (_bookmarkService.containsUrl(tab.url)) {
      final existing =
          _bookmarkService.items.firstWhere((b) => b.url == tab.url);
      await _bookmarkService.remove(existing.id);
    } else {
      await _bookmarkService.add(Bookmark(
        title: tab.title.isEmpty ? tab.url : tab.title,
        url: tab.url,
        folder: 'bar',
      ));
    }
    setState(() {});
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => HistorySheet(
        historyService: _historyService,
        onOpenUrl: (url) {
          final tab = _activeTab;
          if (tab != null) {
            _tabLeftRoot[tab.id] = true;
            _loadInTab(tab.id, url);
          }
        },
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _openActivityLog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ActivityLogSheet(logService: _activityLog),
    );
  }

  void _openPrivacy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => PrivacySheet(
        engine: _engine,
        historyService: _historyService,
        activityLog: _activityLog,
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SettingsSheet(
        dohService: _dohService,
        diversityService: _diversityService,
        passwordService: _passwordService,
        downloadService: _downloadService,
        engine: _engine,
        onChanged: () => setState(() {}),
        onOpenHistory: _openHistory,
        onOpenActivityLog: _openActivityLog,
        onOpenPrivacy: _openPrivacy,
      ),
    );
  }

  void _openDownloadsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final items = _downloadService.items;
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Tải xuống',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Chưa có tải xuống nào',
                          style: TextStyle(color: Colors.white54)),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final d = items[i];
                          return ListTile(
                            title: Text(d.fileName,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${d.status.name} · ${(d.progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (d.status == DownloadStatus.downloading)
                                  IconButton(
                                    icon: const Icon(Icons.pause),
                                    onPressed: () async {
                                      await _downloadService.pause(d.id);
                                      setSheetState(() {});
                                    },
                                  ),
                                if (d.status == DownloadStatus.paused)
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () async {
                                      await _downloadService.resume(d.id);
                                      setSheetState(() {});
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () async {
                                    await _downloadService.remove(d.id);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
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
      },
    );
  }

  @override
  void dispose() {
    _findCtrl.dispose();
    _omniboxController.dispose();
    _engine.dispose();
    super.dispose();
  }

  /// Cùng site? (bỏ www. và so sánh host)
  bool _sameSite(String a, String b) {
    String host(String u) {
      try {
        final uri = Uri.parse(u.contains('://') ? u : 'https://$u');
        return uri.host.replaceFirst(RegExp(r'^www\\.'), '');
      } catch (_) {
        return u;
      }
    }
    return host(a) == host(b);
  }

  /// Back hệ thống:
  /// - Chưa gõ URL / bookmark (còn session trang chủ) → về Dashboard ngay
  ///   (tránh kẹt redirect Google / consent)
  /// - Đã chủ động đi trang khác + còn history → lùi WebView
  /// - Hết history → về Dashboard
  Future<void> _handleSystemBack() async {
    final tab = _activeTab;
    if (tab == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final leftRoot = _tabLeftRoot[tab.id] == true;

    // Chưa từng chủ động điều hướng → thoát Browser luôn
    if (!leftRoot) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final canBack = await _engine.canGoBack(tab.id);
      if (canBack) {
        await _engine.goBack(tab.id);
        return;
      }
    } catch (_) {}

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final active = _activeTab;

    // Chrome (TabStrip + Omnibox + BookmarkBar) nằm trong Material riêng
    // phía trên Expanded(WebView). Hybrid Composition + chỉ mount 1 WebView
    // active → Omnibox/TabStrip nhận đủ gesture, không bị PlatformView đè.
    //
    // Nút Back hệ thống: lùi WebView history trước; hết history mới pop về Dashboard.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 4,
              shadowColor: Colors.black54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabStrip(
                    tabs: _tabs,
                    activeTabId: _activeTabId,
                    onSelect: _switchTab,
                    onClose: _closeTab,
                    onAdd: () => _addTab(activate: true),
                    onAddIncognito: () =>
                        _addTab(activate: true, incognito: true),
                  ),
                  
                  if (_findVisible)
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _findCtrl,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Tìm trong trang…',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _runFind(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up),
                              onPressed: () => _runFind(forward: false),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              onPressed: () => _runFind(forward: true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _toggleFind,
                            ),
                          ],
                        ),
                      ),
                    ),

                  Material(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                    child: SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Tìm trong trang',
                            icon: const Icon(Icons.find_in_page, size: 20),
                            onPressed: _toggleFind,
                          ),
                          IconButton(
                            tooltip: 'Reader mode',
                            icon: const Icon(Icons.chrome_reader_mode_outlined, size: 20),
                            onPressed: _runReader,
                          ),
                          const Spacer(),
                          Text(
                            'Tìm: ${searchEngineService.current.name}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
Omnibox(
                    controller: _omniboxController,
                    canGoBack: active?.canGoBack ?? false,
                    canGoForward: active?.canGoForward ?? false,
                    isLoading: active?.isLoading ?? false,
                    progress: active?.progress ?? 0,
                    isBookmarked: active != null &&
                        active.url != 'about:blank' &&
                        _bookmarkService.containsUrl(active.url),
                    onBack: () =>
                        active != null ? _engine.goBack(active.id) : null,
                    onForward: () =>
                        active != null ? _engine.goForward(active.id) : null,
                    onReload: () => active != null
                        ? (active.isLoading
                            ? _engine.stopLoading(active.id)
                            : _engine.reload(active.id))
                        : null,
                    onSubmit: _onOmniboxSubmit,
                    onToggleBookmark: _toggleBookmark,
                    onOpenSettings: _openSettings,
                    onOpenDownloads: _openDownloadsSheet,
                  ),
                  if (_bookmarkService.barItems.isNotEmpty)
                    BookmarkBar(
                      bookmarks: _bookmarkService.barItems,
                      onTap: (b) {
                        if (active != null) {
                          _tabLeftRoot[active.id] = true;
                          _loadInTab(active.id, b.url);
                        }
                      },
                    ),
                ],
              ),
            ),
            // Chỉ mount WebView của tab active — tránh nhiều PlatformView
            // cùng tranh gesture (IndexedStack giữ tất cả WebView sống).
            Expanded(
              child: active == null
                  ? const SizedBox.shrink()
                  : KeyedSubtree(
                      key: ValueKey('active_web_${active.id}'),
                      child: _engine.buildView(
                        tabId: active.id,
                        onCreated: () {},
                      ),
                    ),
            ),
          ],
        ),
      ),
      ), // Scaffold
    ); // PopScope
  }
}
