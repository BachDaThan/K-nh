import 'package:flutter/material.dart';

import '../services/app_launcher_service.dart';

/// Bottom sheet hiển thị danh sách app đã cài, cho phép tìm kiếm + ghim.
class AppPickerSheet extends StatefulWidget {
  final AppLauncherService service;

  const AppPickerSheet({super.key, required this.service});

  @override
  State<AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<AppPickerSheet> {
  List<InstalledApp> _all = [];
  List<InstalledApp> _filtered = [];
  List<String> _pinned = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await widget.service.listInstalledApps();
    final pinned = await widget.service.getPinnedPackageNames();
    if (!mounted) return;
    setState(() {
      _all = apps;
      _filtered = apps;
      _pinned = pinned;
      _loading = false;
    });
  }

  void _filter(String q) {
    setState(() {
      _query = q;
      _filtered = q.trim().isEmpty
          ? _all
          : _all
              .where((a) =>
                  a.name.toLowerCase().contains(q.trim().toLowerCase()))
              .toList();
    });
  }

  Future<void> _togglePin(InstalledApp app) async {
    final isPinned = _pinned.contains(app.packageName);
    if (isPinned) {
      await widget.service.unpin(app.packageName);
    } else {
      await widget.service.pin(app.packageName);
    }
    if (!mounted) return;
    setState(() {
      if (isPinned) {
        _pinned.remove(app.packageName);
      } else {
        _pinned.add(app.packageName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Ghim App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: _filter,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm app…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              _query.isEmpty
                                  ? 'Không tìm thấy app nào trên máy.'
                                  : 'Không có app khớp "$_query".',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final app = _filtered[index];
                              final isPinned =
                                  _pinned.contains(app.packageName);
                              return ListTile(
                                leading: app.icon != null
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.memory(
                                          app.icon!,
                                          width: 36,
                                          height: 36,
                                        ),
                                      )
                                    : const Icon(Icons.android,
                                        color: Colors.white38, size: 36),
                                title: Text(
                                  app.name,
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    color: isPinned
                                        ? const Color(0xFF6C8CFF)
                                        : Colors.white38,
                                  ),
                                  onPressed: () => _togglePin(app),
                                ),
                                onTap: () => _togglePin(app),
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
