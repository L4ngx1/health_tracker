import 'package:flutter/material.dart';

import '../../controllers/main_navigation_controller.dart';
import '../../core/theme/app_palette.dart';
import '../../models/bottom_nav_item.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'notes_screen.dart';
import 'nutrition_screen.dart';
import 'workout_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final controller = MainNavigationController();
  int? _pressedIndex;

  final pages = const [
    HomeScreen(),
    WorkoutScreen(),
    NutritionScreen(),
    NotesScreen(),
    JournalScreen(),
  ];

  final items = const [
    BottomNavItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    BottomNavItem(
      label: 'Tập luyện',
      icon: Icons.sports_gymnastics_outlined,
      activeIcon: Icons.sports_gymnastics,
    ),
    BottomNavItem(
      label: 'Ăn uống',
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt,
    ),
    BottomNavItem(
      label: 'Ghi chú',
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
    ),
    BottomNavItem(
      label: 'Nhật ký',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(index: controller.index, children: pages),
          floatingActionButton: controller.index == 1
              ? FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: AppPalette.primaryDark,
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: keyboardVisible
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A1B7D5B),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 62,
                      child: Row(
                        children: List.generate(items.length, (i) {
                          final selected = controller.index == i;
                          final item = items[i];
                          return Expanded(
                            child: AnimatedScale(
                              scale: _pressedIndex == i ? 0.92 : 1,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  splashColor: AppPalette.primary.withValues(
                                    alpha: 0.16,
                                  ),
                                  highlightColor: AppPalette.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  onHighlightChanged: (isPressed) {
                                    setState(() {
                                      _pressedIndex = isPressed ? i : null;
                                    });
                                  },
                                  onTap: () => controller.setIndex(i),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      curve: Curves.easeOut,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppPalette.primary.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              selected
                                                  ? item.activeIcon
                                                  : item.icon,
                                              size: 22,
                                              color: selected
                                                  ? AppPalette.primary
                                                  : const Color(0xFF95A39B),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              item.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: selected
                                                    ? AppPalette.primary
                                                    : const Color(0xFF95A39B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
