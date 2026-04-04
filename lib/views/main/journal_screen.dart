import 'package:flutter/material.dart';

import '../../controllers/journal_controller.dart';
import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/journal_entry_item.dart';
import '../widgets/common_widgets.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final JournalController _controller = JournalController();
  final MainNavigationController _navController = MainNavigationController();
  List<JournalEntryItem> _entries = <JournalEntryItem>[];
  bool _isLoading = false;

  Future<void> _openNoteEditor({JournalEntryItem? entry}) async {
    final controller = TextEditingController(text: entry?.note ?? '');
    final noteFocusNode = FocusNode();
    final isEditing = entry != null;

    FocusScope.of(context).unfocus();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(sheetContext).unfocus(),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Sửa ghi chú' : 'Thêm ghi chú',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    focusNode: noteFocusNode,
                    autofocus: false,
                    minLines: 3,
                    maxLines: 6,
                    onTapOutside: (_) => noteFocusNode.unfocus(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập nội dung ghi chú...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(sheetContext);
                            final text = controller.text.trim();
                            if (text.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập nội dung ghi chú.')),
                              );
                              return;
                            }

                            final ok = isEditing
                                ? await _controller.updateNote(entry: entry, note: text)
                                : await _controller.addNote(text);
                            if (!mounted) return;
                            navigator.pop();
                            await _loadEntries();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? (isEditing
                                          ? 'Đã cập nhật ghi chú.'
                                          : 'Đã thêm ghi chú.')
                                      : (isEditing
                                          ? 'Không thể cập nhật ghi chú.'
                                          : 'Không thể thêm ghi chú.'),
                                ),
                              ),
                            );
                          },
                          child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm'),
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
    } finally {
      noteFocusNode.dispose();
      controller.dispose();
    }
  }

  Future<void> _deleteEntry(JournalEntryItem entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final deleted = await _controller.deleteNote(entry);
    if (!mounted) return;
    await _loadEntries();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Đã xóa ghi chú.' : 'Không thể xóa ghi chú.',
        ),
      ),
    );
  }

  Future<void> _showEntryDetails(JournalEntryItem entry) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Chi tiết ghi chú'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (entry.subtitle != null && entry.subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    entry.subtitle!,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.74),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (entry.canManage)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openNoteEditor(entry: entry);
                },
                child: const Text('Sửa'),
              ),
            if (entry.canManage)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _deleteEntry(entry);
                },
                child: const Text('Xóa'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _navController.addListener(_onNavChanged);
    _loadEntries();
  }

  @override
  void dispose() {
    _navController.removeListener(_onNavChanged);
    super.dispose();
  }

  void _onNavChanged() {
    if (_navController.index == 4) {
      _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final items = await _controller.getEntries(context);
    if (!mounted) return;
    setState(() {
      _entries = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: AppStrings.journalScreenTitle(context),
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.journalFrameTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(AppStrings.journalFrameSubtitle(context)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemBuilder: (_, i) => InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showEntryDetails(_entries[i]),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.notes,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _entries[i].title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      if (_entries[i].subtitle != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _entries[i].subtitle!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.72),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_entries[i].canManage)
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        await _openNoteEditor(entry: _entries[i]);
                                        return;
                                      }
                                      if (value == 'delete') {
                                        await _deleteEntry(_entries[i]);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text('Sửa'),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Xóa'),
                                      ),
                                    ],
                                  )
                                else
                                  const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemCount: _entries.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
