import 'package:flutter/material.dart';
import 'addon_service.dart';

class AddonSheet extends StatefulWidget {
  const AddonSheet({super.key});

  @override
  State<AddonSheet> createState() => _AddonSheetState();
}

class _AddonSheetState extends State<AddonSheet> {
  late final TextEditingController _css;
  late final TextEditingController _js;
  late final TextEditingController _listUrl;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _css = TextEditingController(text: addonService.userCss);
    _js = TextEditingController(text: addonService.userJs);
    _listUrl = TextEditingController(
      text: 'https://raw.githubusercontent.com/easylist/easylist/master/easylist/easylist_adservers.txt',
    );
    addonService.load().then((_) {
      _css.text = addonService.userCss;
      _js.text = addonService.userJs;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _css.dispose();
    _js.dispose();
    _listUrl.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    addonService.userCss = _css.text;
    addonService.userJs = _js.text;
    await addonService.save();
    setState(() => _msg = 'Đã lưu. Tải lại trang để áp CSS/JS.');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.96,
      builder: (ctx, scroll) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scroll,
            children: [
              const Text('Tiện ích giả (bản Plus)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Không phải Firefox/Chrome store. '
                'CSS/JS chạy trong trang + list host chặn thêm.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bật tiện ích giả'),
                value: addonService.enabled,
                onChanged: (v) async {
                  addonService.enabled = v;
                  await addonService.save();
                  setState(() {});
                },
              ),
              const Divider(),
              const Text('User CSS', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _css,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'img { opacity: 0.9 }',
                ),
              ),
              const SizedBox(height: 12),
              const Text('User JS', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _js,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'console.log("kinh-plus")',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _persist, child: const Text('Lưu CSS/JS')),
              const Divider(height: 28),
              const Text('Filter list (host)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'Đang có ${addonService.extraHosts.length} host.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
              TextField(
                controller: _listUrl,
                decoration: const InputDecoration(
                  labelText: 'URL list',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  try {
                    final n =
                        await addonService.importHostList(_listUrl.text.trim());
                    setState(() => _msg = 'Đã nhập $n host');
                  } catch (e) {
                    setState(() => _msg = 'Lỗi: $e');
                  }
                },
                child: const Text('Tải list vào app'),
              ),
              if (_msg != null) ...[
                const SizedBox(height: 10),
                Text(_msg!),
              ],
            ],
          ),
        );
      },
    );
  }
}
