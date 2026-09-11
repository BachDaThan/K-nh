import 'package:flutter/material.dart';
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

  final _bookmarkService = BookmarkService();
  final _dohService = DohService();
  final _downloadService = DownloadService();
  final _passwordService = PasswordService();
  final _diversityService = SearchDiversityService();

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
        // Đánh dấu đã rời trang chủ tab nếu URL khác root
        final root = _tabRootUrl[tabId];
        if (root != null && u.isNotEmpty && u != 'about:blank') {
          if (!_sameSite(root, u)) {
            _tabLeftRoot[tabId] = true;
          }
        }
      }
    };
    _engine.onProgressChanged = (tabId, progress) {
      final t = _findTab(tabId);
      if (t != null && mounted) setState(() => t.progress = progress);
    };
    _engine.onLoadingChanged = (tabId, loading) {
      final t = _findTab(tabId);
      if (t != null && mounted) setState(() => t.isLoading = loading);
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

  void _addTab({bool activate = true, String? initialUrl}) {
    final tab = BrowserTab();
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
        : 'https://www.google.com';
    _tabRootUrl[tab.id] = url;
    _tabLeftRoot[tab.id] = false;
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

  Future<void> _loadInTab(String tabId, String raw) async {
    // Áp dụng Search Diversity nếu là từ khóa tìm kiếm.
    final looksLikeUrl =
        raw.contains('://') || (raw.contains('.') && !raw.contains(' '));
    final query = looksLikeUrl ? raw : _diversityService.transformQuery(raw);
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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
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
      ),
    );
  }

  void _openDownloadsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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
  /// - Đang ở trang chủ tab (chưa đi đâu) → về Dashboard ngay
  /// - Còn lịch sử WebView → lùi trang
  /// - Hết lịch sử → về Dashboard
  Future<void> _handleSystemBack() async {
    final tab = _activeTab;
    if (tab == null) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    final leftRoot = _tabLeftRoot[tab.id] == true;
    final canBack = await _engine.canGoBack(tab.id);

    // Chưa từng rời trang chủ tab → Back = thoát Browser (không kẹt redirect Google)
    if (!leftRoot) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    if (canBack) {
      await _engine.goBack(tab.id);
      return;
    }

    if (mounted) Navigator.of(context).maybePop();
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
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: const Color(0xFF1A1A1A),
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
                        if (active != null) _loadInTab(active.id, b.url);
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
