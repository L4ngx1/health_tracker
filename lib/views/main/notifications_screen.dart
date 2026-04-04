import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/backend/notification_record.dart';
import '../../services/backend_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final BackendApiService _backendApiService = BackendApiService();
  final Set<String> _optimisticReadIds = <String>{};

  String _normalizeLegacyText(String raw) {
    var text = raw;
    const replacements = <String, String>{
      'Buoi tap da duoc luu': 'Buổi tập đã được lưu',
      'Ban vua luu': 'Bạn vừa lưu',
      'AI da tao ke hoach moi': 'AI đã tạo kế hoạch mới',
      'Ke hoach tap luyen da duoc cap nhat theo muc tieu va can nang hien tai.':
          'Kế hoạch tập luyện đã được cập nhật theo mục tiêu và cân nặng hiện tại.',
      ' phut': ' phút',
      ' gio': ' giờ',
      ' ngay': ' ngày',
    };
    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });
    return text;
  }

  String _relativeTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _markRead(NotificationRecord item) async {
    if (item.isRead || _optimisticReadIds.contains(item.id)) return;

    setState(() {
      _optimisticReadIds.add(item.id);
    });

    try {
      await _backendApiService.markMyNotificationRead(item.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticReadIds.remove(item.id);
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật trạng thái đã đọc: $e')),
      );
    }
  }

  Future<void> _markAllRead({bool? onlyImportant}) async {
    try {
      await _backendApiService.markAllMyNotificationsRead(
        onlyImportant: onlyImportant,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu đã đọc.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đánh dấu đã đọc: $e')),
      );
    }
  }

  Future<void> _openNotificationDetail(NotificationRecord item) async {
    await _markRead(item);
    if (!mounted) return;

    final title = _normalizeLegacyText(item.title);
    final message = _normalizeLegacyText(item.message);
    final time = _relativeTime(item.createdAt);
    final dt = item.createdAt;
    final dateText =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: item.isImportant
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      child: Icon(
                        item.isImportant
                            ? Icons.priority_high_rounded
                            : Icons.notifications_active_outlined,
                        color: item.isImportant
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.isImportant
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.isImportant ? 'Quan trọng' : 'Thông báo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.isImportant
                              ? colorScheme.onErrorContainer
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tạo lúc: $dateText',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Đóng'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _deleteNotification(item);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Xóa thông báo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteNotification(NotificationRecord item) async {
    try {
      await _backendApiService.deleteMyNotification(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa thông báo.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa thông báo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surface,
          scrolledUnderElevation: 0,
          elevation: 0,
          title: const Text('Thông báo'),
          centerTitle: false,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'all') {
                  _markAllRead();
                  return;
                }
                if (value == 'important') {
                  _markAllRead(onlyImportant: true);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'all',
                  child: Text('Đánh dấu tất cả đã đọc'),
                ),
                PopupMenuItem<String>(
                  value: 'important',
                  child: Text('Đánh dấu Quan trọng đã đọc'),
                ),
              ],
            ),
          ],
        ),
        body: StreamBuilder<List<NotificationRecord>>(
          stream: _backendApiService.watchMyNotifications(limit: 200),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              return const Center(
                child: Text('Vui lòng đăng nhập để xem thông báo.'),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi tải thông báo: ${snapshot.error}'),
                ),
              );
            }

            final allItems = snapshot.data ?? const <NotificationRecord>[];
            final importantItems = allItems
                .where((item) => item.isImportant)
                .toList(growable: false);
            final unreadAll = allItems
                .where((item) =>
                    !(item.isRead || _optimisticReadIds.contains(item.id)))
                .length;
            final importantCount = importantItems.length;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mark_email_unread_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          unreadAll <= 0
                              ? 'Bạn đã đọc tất cả thông báo.'
                              : 'Bạn có $unreadAll thông báo chưa đọc.',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (unreadAll > 0)
                        TextButton(
                          onPressed: _markAllRead,
                          child: const Text('Đọc tất cả'),
                        ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: 'Tất cả (${allItems.length})'),
                    Tab(text: 'Quan trọng ($importantCount)'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _NotificationList(
                        items: allItems,
                        onTap: _openNotificationDetail,
                        onDelete: _deleteNotification,
                        optimisticReadIds: _optimisticReadIds,
                        timeFormatter: _relativeTime,
                        textNormalizer: _normalizeLegacyText,
                      ),
                      _NotificationList(
                        items: importantItems,
                        onTap: _openNotificationDetail,
                        onDelete: _deleteNotification,
                        optimisticReadIds: _optimisticReadIds,
                        timeFormatter: _relativeTime,
                        textNormalizer: _normalizeLegacyText,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: colorScheme.surface,
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.onTap,
    required this.onDelete,
    required this.optimisticReadIds,
    required this.timeFormatter,
    required this.textNormalizer,
  });

  final List<NotificationRecord> items;
  final Future<void> Function(NotificationRecord item) onTap;
  final Future<void> Function(NotificationRecord item) onDelete;
  final Set<String> optimisticReadIds;
  final String Function(DateTime createdAt) timeFormatter;
  final String Function(String raw) textNormalizer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 42,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 10),
              Text(
                'Chưa có thông báo nào.',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Các cập nhật mới sẽ xuất hiện tại đây.',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      itemBuilder: (context, index) {
        final item = items[index];
        final isRead = item.isRead || optimisticReadIds.contains(item.id);
        final icon = item.isImportant
            ? Icons.priority_high_rounded
            : Icons.notifications_outlined;

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Xóa',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Xóa thông báo'),
                    content:
                        const Text('Bạn có chắc muốn xóa thông báo này không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => onDelete(item),
          child: Container(
            decoration: BoxDecoration(
              color: isRead
                  ? colorScheme.surfaceContainerLowest
                  : colorScheme.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: ListTile(
              onTap: () => onTap(item),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: item.isImportant
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: item.isImportant
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                textNormalizer(item.title),
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  textNormalizer(item.message),
                  style: TextStyle(
                    color: isRead
                        ? colorScheme.onSurface.withValues(alpha: 0.72)
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeFormatter(item.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Mới',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              isThreeLine: false,
              dense: false,
              visualDensity: const VisualDensity(vertical: -1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isRead
                      ? colorScheme.outlineVariant
                      : colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: items.length,
    );
  }
}
