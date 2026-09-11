import 'package:flutter/material.dart';

/// Thanh địa chỉ / tìm kiếm.
/// Layout 2 hàng để trên mobile luôn còn chỗ cho TextField (không bị IconButton
/// chiếm hết chiều ngang khiến ô URL biến mất).
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hàng 1: nút điều hướng + tải + menu
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: canGoBack ? onBack : null,
                color: canGoBack ? Colors.white70 : Colors.white24,
                tooltip: 'Back',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: canGoForward ? onForward : null,
                color: canGoForward ? Colors.white70 : Colors.white24,
                tooltip: 'Forward',
              ),
              IconButton(
                icon: Icon(
                  isLoading ? Icons.close_rounded : Icons.refresh_rounded,
                  size: 20,
                ),
                onPressed: onReload,
                color: Colors.white70,
                tooltip: isLoading ? 'Stop' : 'Reload',
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 20),
                onPressed: onOpenDownloads,
                color: Colors.white70,
                tooltip: 'Downloads',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: onOpenSettings,
                color: Colors.white70,
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
        // Hàng 2: ô URL / tìm kiếm full width
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: SizedBox(
            height: 44,
            child: Material(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded,
                      size: 20, color: Colors.white54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      cursorColor: const Color(0xFF6C8CFF),
                      textInputAction: TextInputAction.go,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm hoặc nhập URL',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: onSubmit,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isBookmarked
                          ? const Color(0xFF6C8CFF)
                          : Colors.white54,
                    ),
                    onPressed: onToggleBookmark,
                    tooltip: 'Bookmark',
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading || progress > 0 && progress < 1)
          LinearProgressIndicator(
            value: progress > 0 && progress < 1 ? progress : null,
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: const Color(0xFF6C8CFF),
          ),
      ],
    );
  }
}
