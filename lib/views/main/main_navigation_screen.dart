import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.72) ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    final items = [
      BottomNavItem(
        label: AppStrings.navHome(context),
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      BottomNavItem(
        label: AppStrings.navWorkout(context),
        icon: Icons.sports_gymnastics_outlined,
        activeIcon: Icons.sports_gymnastics,
      ),
      BottomNavItem(
        label: AppStrings.navNutrition(context),
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu,
      ),
      BottomNavItem(
        label: AppStrings.navNotes(context),
        icon: Icons.article_outlined,
        activeIcon: Icons.article,
      ),
      BottomNavItem(
        label: AppStrings.navJournal(context),
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book,
      ),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: List.generate(pages.length, (i) {
              final active = controller.index == i;
              return IgnorePointer(
                ignoring: !active,
                child: RepaintBoundary(
                  child: AnimatedOpacity(
                    opacity: active ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: active ? Offset.zero : const Offset(0.028, 0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: pages[i],
                    ),
                  ),
                ),
              );
            }),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
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
                            splashColor: colorScheme.primary.withValues(
                              alpha: 0.16,
                            ),
                            highlightColor: colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            onHighlightChanged: (isPressed) {
                              setState(() {
                                _pressedIndex = isPressed ? i : null;
                              });
                            },
                            onTap: () {
                              if (controller.index != i) {
                                HapticFeedback.selectionClick();
                              }
                              controller.setIndex(i);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        selected ? item.activeIcon : item.icon,
                                        size: 22,
                                        color: selected
                                            ? colorScheme.primary
                                            : unselectedColor,
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
                                              ? colorScheme.primary
                                              : unselectedColor,
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
