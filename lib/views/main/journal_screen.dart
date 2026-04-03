import 'package:flutter/material.dart';

import '../../controllers/journal_controller.dart';
import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/journal_entry_item.dart';
import '../widgets/common_widgets.dart';

enum _JournalRange { day, week, month, all }

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
  _JournalRange _range = _JournalRange.day;

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

  DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _weekStart(DateTime value) {
    final start = _dayStart(value);
    return start.subtract(Duration(days: start.weekday - DateTime.monday));
  }

  bool _matchesRange(JournalEntryItem item) {
    final date = item.sortAt;
    if (date == null) return _range == _JournalRange.all;
    final today = _dayStart(DateTime.now());
    final day = _dayStart(date);
    switch (_range) {
      case _JournalRange.day:
        return day == today;
      case _JournalRange.week:
        final start = _weekStart(DateTime.now());
        return !day.isBefore(start) && !day.isAfter(today);
      case _JournalRange.month:
        return day.year == today.year && day.month == today.month;
      case _JournalRange.all:
        return true;
    }
  }

  String _groupKey(JournalEntryItem item) {
    final date = item.sortAt ?? DateTime.now();
    final day = _dayStart(date);
    return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  String _groupLabel(BuildContext context, DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    final today = _dayStart(DateTime.now());
    final day = _dayStart(date);
    if (day == today) return 'Hôm nay';
    if (day == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return localizations.formatFullDate(date);
  }

  IconData _iconForEntry(JournalEntryItem entry) {
    if (entry.kind == 'daily_summary') return Icons.monitor_heart_outlined;
    return Icons.notes;
  }

  Widget _buildEntryDetails(BuildContext context, JournalEntryItem entry) {
    final chips = <Widget>[];
    if (entry.steps != null) {
      chips.add(_metricChip(Icons.directions_walk, '${entry.steps} bước'));
    }
    if (entry.sleepMinutes != null) {
      final hours = entry.sleepMinutes! ~/ 60;
      final minutes = entry.sleepMinutes! % 60;
      final sleepText =
          hours > 0 ? '${hours}h ${minutes}m' : '${entry.sleepMinutes} phút';
      chips.add(_metricChip(Icons.bedtime_outlined, sleepText));
    }
    if (entry.waterMl != null) {
      final goalText = entry.waterGoalMl != null && entry.waterGoalMl! > 0
          ? '/${entry.waterGoalMl} ml'
          : 'ml';
      chips.add(
          _metricChip(Icons.water_drop_outlined, '${entry.waterMl}$goalText'));
    }

    if (chips.isEmpty) {
      return Text(
        entry.subtitle?.trim().isNotEmpty == true
            ? entry.subtitle!
            : entry.title,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _metricChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }

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
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
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
                                const SnackBar(
                                    content: Text(
                                        'Vui lòng nhập nội dung ghi chú.')),
                              );
                              return;
                            }

                            final ok = isEditing
                                ? await _controller.updateNote(
                                    entry: entry, note: text)
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
          title: Text(entry.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.subtitle != null &&
                    entry.subtitle!.trim().isNotEmpty) ...[
                  Text(
                    entry.subtitle!,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildEntryDetails(context, entry),
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

  List<JournalEntryItem> _filteredEntries() {
    final filtered = _entries.where(_matchesRange).toList(growable: false);
    filtered.sort((a, b) => (b.sortAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.sortAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredEntries = _filteredEntries();
    final grouped = <String, List<JournalEntryItem>>{};
    for (final entry in filteredEntries) {
      grouped
          .putIfAbsent(_groupKey(entry), () => <JournalEntryItem>[])
          .add(entry);
    }
    final orderedGroups = grouped.entries.toList(growable: false)
      ..sort((a, b) {
        final aDate =
            DateTime.tryParse(a.key) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            DateTime.tryParse(b.key) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Hôm nay'),
                    selected: _range == _JournalRange.day,
                    onSelected: (_) =>
                        setState(() => _range = _JournalRange.day),
                  ),
                  ChoiceChip(
                    label: const Text('Tuần này'),
                    selected: _range == _JournalRange.week,
                    onSelected: (_) =>
                        setState(() => _range = _JournalRange.week),
                  ),
                  ChoiceChip(
                    label: const Text('Tháng này'),
                    selected: _range == _JournalRange.month,
                    onSelected: (_) =>
                        setState(() => _range = _JournalRange.month),
                  ),
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _range == _JournalRange.all,
                    onSelected: (_) =>
                        setState(() => _range = _JournalRange.all),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${filteredEntries.length} mục đã lọc',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredEntries.isEmpty
                        ? Center(
                            child: Text(
                              'Chưa có dữ liệu cho bộ lọc này.',
                              style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemBuilder: (_, index) {
                              final group = orderedGroups[index];
                              final groupDate = DateTime.tryParse(group.key) ??
                                  DateTime.now();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      _groupLabel(context, groupDate),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  ...group.value.map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => _showEntryDetails(entry),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.shadow
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 10,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: colorScheme
                                                    .surfaceContainerHighest,
                                                child: Icon(
                                                  _iconForEntry(entry),
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
                                                      entry.title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700),
                                                    ),
                                                    if (entry.subtitle !=
                                                            null &&
                                                        entry.subtitle!
                                                            .trim()
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        entry.subtitle!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                  alpha: 0.72),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.chevron_right),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemCount: orderedGroups.length,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
