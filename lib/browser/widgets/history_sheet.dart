import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_entry.dart';
import '../services/history_service.dart';

class HistorySheet extends StatefulWidget {
  final HistoryService historyService;
  final void Function(String url) onOpenUrl;
  final VoidCallback onChanged;

  const HistorySheet({
    super.key,
    required this.historyService,
    required this.onOpenUrl,
    required this.onChanged,
  });

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  final _search = TextEditingController();
  String? _filterDomain;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<HistoryEntry> get _filtered {
    var list = _filterDomain != null
        ? widget.historyService.byDomain(_filterDomain!)
        : widget.historyService.search(_search.text);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    final domains = widget.historyService.domains;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('Lịch sử',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.historyService.items.isEmpty
                        ? null
                        : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Xóa toàn bộ lịch sử?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Hủy')),
                                  FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Xóa')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await widget.historyService.clearAll();
                              widget.onChanged();
                              setState(() => _filterDomain = null);
                            }
                          },
                    child: const Text('Xóa hết'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm trong lịch sử...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (domains.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _filterDomain == null,
                        onSelected: (_) =>
                            setState(() => _filterDomain = null),
                      ),
                      const SizedBox(width: 6),
                      ...domains.map((d) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(d),
                              selected: _filterDomain == d,
                              onSelected: (_) =>
                                  setState(() => _filterDomain = d),
                              onDeleted: () async {
                                await widget.historyService.clearDomain(d);
                                widget.onChanged();
                                setState(() {
                                  if (_filterDomain == d) _filterDomain = null;
                                });
                              },
                              deleteIcon: const Icon(Icons.close, size: 16),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text('Chưa có lịch sử',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final e = _filtered[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.public, size: 20),
                            title: Text(e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${e.domain} · ${fmt.format(e.visitedAt)}',
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white54),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onOpenUrl(e.url);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                await widget.historyService.remove(e.id);
                                widget.onChanged();
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
}
