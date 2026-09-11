import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_event.dart';
import '../services/activity_log_service.dart';

class ActivityLogSheet extends StatefulWidget {
  final ActivityLogService logService;

  const ActivityLogSheet({super.key, required this.logService});

  @override
  State<ActivityLogSheet> createState() => _ActivityLogSheetState();
}

class _ActivityLogSheetState extends State<ActivityLogSheet> {
  IconData _icon(ActivityKind k) {
    switch (k) {
      case ActivityKind.navigation:
        return Icons.navigation_outlined;
      case ActivityKind.pageFinished:
        return Icons.check_circle_outline;
      case ActivityKind.error:
        return Icons.error_outline;
      case ActivityKind.download:
        return Icons.download;
      case ActivityKind.cookieClear:
      case ActivityKind.cacheClear:
      case ActivityKind.historyClear:
        return Icons.cleaning_services_outlined;
      case ActivityKind.incognitoStart:
      case ActivityKind.incognitoEnd:
        return Icons.visibility_off_outlined;
      case ActivityKind.settings:
        return Icons.settings_outlined;
      case ActivityKind.other:
        return Icons.info_outline;
    }
  }

  Color _color(ActivityKind k) {
    switch (k) {
      case ActivityKind.error:
        return Colors.redAccent;
      case ActivityKind.incognitoStart:
      case ActivityKind.incognitoEnd:
        return Colors.purpleAccent;
      case ActivityKind.pageFinished:
        return Colors.greenAccent;
      default:
        return const Color(0xFF6C8CFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    final items = widget.logService.items;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
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
                  const Text('Activity Log',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: items.isEmpty
                        ? null
                        : () async {
                            await widget.logService.clearAll();
                            setState(() {});
                          },
                    child: const Text('Xóa log'),
                  ),
                ],
              ),
              Text(
                'Nhật ký minh bạch: điều hướng, lỗi, dọn dẹp, ẩn danh…\n'
                'Sự kiện ẩn danh chỉ nằm RAM (không ghi đĩa).',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('Chưa có sự kiện',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final e = items[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(_icon(e.kind),
                                color: _color(e.kind), size: 22),
                            title: Text(e.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(
                              [
                                fmt.format(e.at),
                                if (e.domain != null) e.domain!,
                                if (e.ephemeral) 'RAM',
                              ].join(' · '),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white54),
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
