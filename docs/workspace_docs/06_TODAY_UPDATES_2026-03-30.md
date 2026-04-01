# Today Updates - 2026-03-30

## Scope
This document summarizes all completed items today for health_tracker_app.

## Completed Items
1. User icon navigation to profile
- Updated TopBar user icon to be tappable.
- Wired navigation from main screens to Profile screen.
- Files:
  - lib/views/widgets/common_widgets.dart
  - lib/views/main/home_screen.dart
  - lib/views/main/workout_screen.dart
  - lib/views/main/nutrition_screen.dart
  - lib/views/main/notes_screen.dart
  - lib/views/main/journal_screen.dart

2. User avatar behavior by login type
- If user signs in with Google, TopBar avatar shows Google profile image.
- If not Google sign-in, app default icon is shown.
- File:
  - lib/views/widgets/common_widgets.dart

3. User/Profile UI alignment with app design
- Redesigned Profile and Settings screens to match app visual language.
- Added consistent gradient background, card style, typography, and button treatment.
- Files:
  - lib/views/main/profile_screen.dart
  - lib/views/main/settings_screen.dart

4. Smoothness improvements across app
- Added smoother global page transitions via theme-level transitions.
- Improved custom route transitions (fade + slide + subtle outgoing parallax).
- Improved tab switching animation in main navigation.
- Files:
  - lib/core/theme/app_theme.dart
  - lib/core/routes/route_transitions.dart
  - lib/views/main/main_navigation_screen.dart

5. Distance data scoped by account (local)
- Updated storage keys to include account scope (uid/anon/guest).
- Affected tracking and movement config persistence.
- Files:
  - lib/controllers/tracking_controller.dart
  - lib/views/main/home_screen.dart

6. Firebase cloud persistence for distance data
- Implemented Firestore sync service for daily tracking + movement config.
- Synced today tracking data (steps, distance, sleep, goals) per uid.
- Synced movement config and distance history per uid.
- Added cloud merge on load and throttled cloud writes.
- Files:
  - lib/services/health_cloud_sync_service.dart
  - lib/controllers/tracking_controller.dart
  - lib/views/main/home_screen.dart

7. Legacy local-data migration
- Added one-time migration from legacy unscoped SharedPreferences keys
  to account-scoped keys.
- Added migration flags to avoid re-running.
- Files:
  - lib/controllers/tracking_controller.dart
  - lib/views/main/home_screen.dart

8. Firestore security rules update
- Added user-scoped access rules:
  - users/{uid}/** can be read/write only by request.auth.uid == uid.
- File:
  - firestore.rules

## Firestore Data Paths
- users/{uid}/health_tracking/{yyyy-MM-dd}
- users/{uid}/health_tracking_config/movement

## Operational Note
Deploy rules after pull/update:
- firebase deploy --only firestore:rules

## Verification Snapshot
- flutter analyze: No issues found.
