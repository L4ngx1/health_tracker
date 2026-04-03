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
  final JournalController _controller = const JournalController();
  final MainNavigationController _navController = MainNavigationController();
  List<JournalEntryItem> _entries = const [];

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
    _reloadEntries();
  }

  @override
  void dispose() {
    _navController.removeListener(_onNavChanged);
    super.dispose();
  }

  void _onNavChanged() {
    if (_navController.index == 4) {
      _reloadEntries();
    }
  }

  Future<void> _reloadEntries() async {
    final items = await _controller.getEntries(context);
    if (!mounted) return;
    setState(() => _entries = items);
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
                child: ListView.separated(
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
                            color: colorScheme.shadow.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.notes, color: colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
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
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
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
