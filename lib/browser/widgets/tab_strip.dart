import 'package:flutter/material.dart';
import '../models/browser_tab.dart';

class TabStrip extends StatelessWidget {
  final List<BrowserTab> tabs;
  final String? activeTabId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final VoidCallback onAdd;
  final VoidCallback? onAddIncognito;

  const TabStrip({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onSelect,
    required this.onClose,
    required this.onAdd,
    this.onAddIncognito,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final active = tab.id == activeTabId;
                return GestureDetector(
                  onTap: () => onSelect(tab.id),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? (tab.isIncognito
                              ? Colors.purple.withOpacity(0.2)
                              : Colors.white.withOpacity(0.12))
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? (tab.isIncognito
                                ? Colors.purpleAccent.withOpacity(0.6)
                                : const Color(0xFF6C8CFF).withOpacity(0.5))
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (tab.isLoading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        else
                          Icon(
                            tab.isIncognito
                                ? Icons.visibility_off
                                : Icons.public,
                            size: 14,
                            color: tab.isIncognito
                                ? Colors.purpleAccent
                                : Colors.white54,
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tab.title.isEmpty
                                ? (tab.isIncognito ? 'Ẩn danh' : 'Tab mới')
                                : tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onClose(tab.id),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: onAdd,
            color: Colors.white70,
            tooltip: 'Tab mới',
          ),
          if (onAddIncognito != null)
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              onPressed: onAddIncognito,
              color: Colors.purpleAccent,
              tooltip: 'Tab ẩn danh',
            ),
        ],
      ),
    );
  }
}
