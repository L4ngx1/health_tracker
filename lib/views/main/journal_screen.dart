import 'package:flutter/material.dart';

import '../../controllers/journal_controller.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const controller = JournalController();
    final entries = controller.getEntries();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: 'Nhat ky suc khoe -\nSong Khoe'),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khung trang Nhat ky',
                    style: TextStyle(
                      fontSize: 34,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Trang nay duoc tao san de ban tiep tuc gan noi dung ghi chep sau.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE4EFEA),
                        child: Icon(Icons.notes, color: AppPalette.primaryDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entries[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemCount: entries.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
