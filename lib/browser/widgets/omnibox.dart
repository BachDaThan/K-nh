import 'package:flutter/material.dart';

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
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
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
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          size: 18, color: Colors.white54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm hoặc nhập URL',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textInputAction: TextInputAction.go,
                          onSubmitted: onSubmit,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: isBookmarked
                              ? const Color(0xFF6C8CFF)
                              : Colors.white54,
                        ),
                        onPressed: onToggleBookmark,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
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
        if (isLoading && progress > 0 && progress < 1)
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
