import 'package:flutter/material.dart';
import '../services/search_engine_service.dart';

class Omnibox extends StatelessWidget {
  final TextEditingController controller;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;
  final double progress;
  final bool isBookmarked;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onReload;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenDownloads;
  final VoidCallback? onEngineChanged;

  const Omnibox({
    super.key,
    required this.controller,
    required this.canGoBack,
    required this.canGoForward,
    required this.isLoading,
    required this.progress,
    required this.isBookmarked,
    this.onBack,
    this.onForward,
    this.onReload,
    required this.onSubmit,
    this.onToggleBookmark,
    this.onOpenSettings,
    this.onOpenDownloads,
    this.onEngineChanged,
  });

  IconData _engineIcon(String id) {
    switch (id) {
      case 'ddg':
        return Icons.privacy_tip_outlined;
      case 'bing':
        return Icons.language;
      case 'brave':
        return Icons.shield_outlined;
      case 'startpage':
        return Icons.lock_outline;
      default:
        return Icons.search;
    }
  }

  Future<void> _pickEngine(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Lần này tìm kiếm trong:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              ...SearchEngineService.engines.map((e) {
                final selected = e.id == searchEngineService.currentId;
                return ListTile(
                  leading: Icon(_engineIcon(e.id),
                      color: selected ? const Color(0xFF6C8CFF) : Colors.white70),
                  title: Text(e.name),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF6C8CFF), size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, e.id),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      await searchEngineService.setEngine(picked);
      onEngineChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eng = searchEngineService.current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: canGoBack ? onBack : null,
                color: canGoBack ? Colors.white70 : Colors.white24,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: canGoForward ? onForward : null,
                color: canGoForward ? Colors.white70 : Colors.white24,
              ),
              IconButton(
                icon: Icon(
                  isLoading ? Icons.close_rounded : Icons.refresh_rounded,
                  size: 20,
                ),
                onPressed: onReload,
                color: Colors.white70,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 20),
                onPressed: onOpenDownloads,
                color: Colors.white70,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: onOpenSettings,
                color: Colors.white70,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: SizedBox(
            height: 44,
            child: Material(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _pickEngine(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(_engineIcon(eng.id), size: 20, color: Colors.white70),
                          const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white54),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm hoặc nhập URL',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: onSubmit,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: isBookmarked ? const Color(0xFF6C8CFF) : Colors.white70,
                    ),
                    onPressed: onToggleBookmark,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (progress > 0 && progress < 1)
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: const Color(0xFF6C8CFF),
          ),
      ],
    );
  }
}
