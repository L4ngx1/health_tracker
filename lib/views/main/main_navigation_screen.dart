import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes/app_routes.dart';

import '../auth/unverified_screen.dart';

import '../../controllers/main_navigation_controller.dart';
import '../../core/theme/app_palette.dart';
import '../../models/bottom_nav_item.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'notes_screen.dart';
import 'nutrition_screen.dart';
import 'workout_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final controller = MainNavigationController();

  final pages = const [
    HomeScreen(),
    WorkoutScreen(),
    NutritionScreen(),
    NotesScreen(),
    JournalScreen(),
    ProfileScreen(),
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
    BottomNavItem(
      label: 'Hồ sơ',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isUnverified = user != null && !user.isAnonymous && !(user.emailVerified);

        if (isUnverified) {
          return const UnverifiedScreen();
        }

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Scaffold(
              drawer: Drawer(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UserAccountsDrawerHeader(
                        accountName: Text(user?.displayName ?? 'Người dùng'),
                        accountEmail: Text(user?.email ?? ''),
                        currentAccountPicture: user?.photoURL != null
                            ? CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!))
                            : const CircleAvatar(child: Icon(Icons.person)),
                        decoration: const BoxDecoration(color: Colors.white),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Hồ sơ'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.profile);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Cài đặt'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.settings);
                        },
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              body: IndexedStack(
                index: controller.index,
                children: pages,
              ),
              floatingActionButton: controller.index == 1
                  ? FloatingActionButton(
                      onPressed: () {},
                      backgroundColor: AppPalette.primaryDark,
                      child: const Icon(Icons.add),
                    )
                  : null,
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 70,
                    child: Row(
                      children: List.generate(items.length, (i) {
                        final selected = controller.index == i;
                        final item = items[i];
                        return Expanded(
                          child: InkWell(
                            onTap: () => controller.setIndex(i),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selected ? item.activeIcon : item.icon,
                                    size: 22,
                                    color: selected
                                        ? AppPalette.primaryDark
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
                                          ? AppPalette.primaryDark
                                          : const Color(0xFF95A39B),
                                    ),
                                  ),
                                ],
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
      },
    );
  }
}
