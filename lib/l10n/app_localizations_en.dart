// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Healthy Living';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get deleteAction => 'Delete';

  @override
  String get logout => 'Log out';

  @override
  String get send => 'Send';

  @override
  String get orLabel => 'OR';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get optionsTitle => 'App preferences';

  @override
  String get optionsSubtitle => 'Adjust your experience to fit your routine.';

  @override
  String get settingsDeleteTitle => 'Delete account';

  @override
  String get settingsDeleteConfirm =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get darkModeTitle => 'Dark mode';

  @override
  String get darkModeSubtitle =>
      'Easier on your eyes at night and can save battery.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle => 'Get reminders for activities and goals.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'Choose your preferred display language.';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get languageEnglish => 'English';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get processing => 'Processing...';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navNotes => 'Notes';

  @override
  String get navJournal => 'Journal';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle =>
      'Sign in to continue tracking and improving your health.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Sign in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get anonymousLogin => 'Sign in anonymously';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle =>
      'Join the healthy living community to track and improve your health every day.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get fullNameRequired => 'Please enter your full name';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Re-enter password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get register => 'Register';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get loginNow => 'Sign in';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email to receive a reset link.';

  @override
  String get emailHintGeneral => 'Enter your email';

  @override
  String get validEmailRequired => 'Please enter a valid email.';

  @override
  String get resetLinkSent =>
      'A password reset link has been sent if your email exists in the system (check spam too).';

  @override
  String get unverifiedTitle => 'Email not verified';

  @override
  String get unverifiedInstruction =>
      'Please check your email and follow the instructions to verify your account.';

  @override
  String sentToEmail(Object email) {
    return 'Sent to: $email';
  }

  @override
  String get resendVerification => 'Resend verification email';

  @override
  String get verifiedCheckAgain => 'I have verified - Check again';

  @override
  String get emailVerifiedSuccess => 'Email has been verified.';

  @override
  String get emailNotVerifiedYet =>
      'Still not verified. Please check your email.';

  @override
  String get profileScreenTitle => 'User profile';

  @override
  String get anonymousAccount => 'Anonymous account';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get emailUnverified => 'Email not verified';

  @override
  String get editProfileDialogTitle => 'Edit profile';

  @override
  String get nameLabel => 'Name';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully.';

  @override
  String get userFallback => 'User';

  @override
  String get noEmail => 'No email';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get accountInfo => 'Account information';

  @override
  String uidPrefix(Object uid) {
    return 'UID: $uid';
  }

  @override
  String get logoutConfirmTitle => 'Log out';

  @override
  String get logoutConfirmContent => 'Are you sure you want to log out?';

  @override
  String get workoutScreenTitle => 'Workout';

  @override
  String get weekGoalTitle => 'This week\'s goal';

  @override
  String get weekGoalProgress => '4/5 sessions';

  @override
  String get weekGoalCalories => '1,240 kcal burned';

  @override
  String get aiWorkoutSuggestionTitle => 'AI workout suggestion';

  @override
  String get aiWorkoutSuggestionHint =>
      'Tap to receive a personalized workout plan from AI';

  @override
  String get aiGeneratePlanButton => 'Generate plan with AI';

  @override
  String get programModesTitle => 'Workout modes';

  @override
  String get allCaps => 'ALL';

  @override
  String get workoutHistoryTitle => 'Workout history';

  @override
  String get nutritionScreenTitle => 'Nutrition prediction';

  @override
  String get nutritionAiSubtitle =>
      'Take or upload a food photo so AI can estimate calories';

  @override
  String get aiReadyTag => '# AI Ready';

  @override
  String get retakePhotoTooltip => 'Retake';

  @override
  String get capturingPhoto => 'Capturing...';

  @override
  String get capturePhoto => 'Take photo';

  @override
  String get pickFromLibrary => 'Choose from gallery';

  @override
  String get tipTitle => 'Tip';

  @override
  String get tipDescription =>
      'Make sure the meal is well-lit so AI can identify ingredients more accurately.';

  @override
  String get cameraNotFound => 'No camera found on this device.';

  @override
  String get cameraOpenFailed =>
      'Unable to open camera. Please grant permission and try again.';

  @override
  String get capturePhotoFailed => 'Cannot take photo. Please try again.';

  @override
  String get galleryAccessFailed =>
      'Cannot access gallery. Please grant permission and try again.';

  @override
  String get notesScreenTitle => 'Health notes';

  @override
  String get tapToRecord => 'Tap to record';

  @override
  String get notesPrompt =>
      'Talk about your health status, diet, or today\'s mood.';

  @override
  String get notesContentTitle => 'NOTE CONTENT';

  @override
  String get autoDetect => 'Auto detect';

  @override
  String get notePlaceholder =>
      'Start speaking to see your notes appear here...';

  @override
  String get tagHealth => '#HEALTH';

  @override
  String get tagDaily => '#DAILY';

  @override
  String get quickMealTitle => 'Meal';

  @override
  String get quickMealSubtitle => 'Track nutrition';

  @override
  String get quickMoodTitle => 'Mood';

  @override
  String get quickMoodSubtitle => 'Track feelings';

  @override
  String get journalScreenTitle => 'Health journal';

  @override
  String get journalFrameTitle => 'Journal frame';

  @override
  String get journalFrameSubtitle =>
      'This page is prepared for you to continue adding notes later.';

  @override
  String journalSampleEntry(int index) {
    return 'Sample note #$index';
  }

  @override
  String get sleepManagementTitle => 'Sleep management';

  @override
  String get lastSleepSession => 'Latest sleep session';

  @override
  String get currentStatusSleeping => 'Current status: Sleeping';

  @override
  String get currentStatusAwake => 'Current status: Awake';

  @override
  String get sleepGoalReference => 'Reference goal: 8h per day';

  @override
  String get sleepHowItWorksTitle => 'How sleep is measured';

  @override
  String get sleepHowBullet1 =>
      '- Accelerometer data is grouped into 1-minute epochs.';

  @override
  String get sleepHowBullet2 =>
      '- Each minute gets an Activity Score from movement threshold hits.';

  @override
  String get sleepHowBullet3 =>
      '- A weighted sliding window classifies sleep/awake minute by minute.';

  @override
  String get sleepHowBullet4 =>
      '- High step count in current minute favors awake classification.';

  @override
  String get sleepHowBullet5 =>
      '- Display has ~1 minute delay because next minute data is needed.';

  @override
  String get sleepHowBullet6 =>
      '- This is reference data and may vary if phone is far from the body.';

  @override
  String get homePermissionTitle => 'Location permission needed';

  @override
  String get homePermissionContent =>
      'You permanently denied location permission (Don\'t ask again).\nPlease open Settings and enable Location to calculate distance.';

  @override
  String get later => 'Later';

  @override
  String get openSettings => 'Open settings';

  @override
  String get movementGoalTitle => 'Movement goal';

  @override
  String todayStats(Object distance, Object steps, Object calories) {
    return 'Today: $distance km â€¢ $steps steps â€¢ $calories kcal';
  }

  @override
  String dailyGoalLabel(Object goal) {
    return 'Daily goal: $goal km';
  }

  @override
  String get last7DaysHistory => 'Last 7 days';

  @override
  String statsForDay(Object day) {
    return 'Stats $day';
  }

  @override
  String goalPercent(int percent) {
    return '$percent% goal';
  }

  @override
  String get distanceLabel => 'DISTANCE';

  @override
  String get stepsLabel => 'STEPS';

  @override
  String get caloriesLabel => 'CALORIES';

  @override
  String get saveGoal => 'Save goal';

  @override
  String get homeTopTitle => 'Healthy with you';

  @override
  String get overviewHealthTitle => 'HEALTH OVERVIEW';

  @override
  String get overviewMotivation => 'Great! You\'re\non the right\ntrack.';

  @override
  String get overviewSubtitle =>
      'Today you kept a steady routine and slept quite well.';

  @override
  String get distanceTodayTitle => 'DISTANCE TODAY';

  @override
  String distanceSubtitle(Object steps, Object calories, Object goal) {
    return '$steps steps\n$calories kcal\nGoal: $goal km/day';
  }

  @override
  String get sleepRecentTitle => 'LATEST SLEEP';

  @override
  String get sleepScoringSleep =>
      'Sleeping (epoch + weighted sliding window scoring).';

  @override
  String get sleepScoringAwake =>
      'Estimated from acceleration + step counts by minute.';

  @override
  String get exploreMore => 'Explore more';

  @override
  String get trainingLabel => 'WORKOUT';

  @override
  String get yogaMorningTitle => '10-minute\nmorning yoga';

  @override
  String get yogaMorningSubtitle => 'Relax your body and start the day gently';

  @override
  String get homeMetricStepsTitle => 'STEPS TODAY';

  @override
  String get homeMetricStepsUnit => 'steps';

  @override
  String get homeMetricStepsSubtitle => '321 kcal\nburned';

  @override
  String get homeMetricWaterTitle => 'WATER INTAKE';

  @override
  String get homeMetricWaterSubtitle => 'Daily goal';

  @override
  String get homeMetricWeightTitle => 'WEIGHT';

  @override
  String get homeMetricWeightSubtitle => 'Stable\nin the last 7\ndays';

  @override
  String get homeMetricSleepTodayTitle => 'SLEEP TODAY';

  @override
  String get homeMetricSleepTodaySubtitle =>
      'Quality: Good\nYou slept enough\n35 minutes more\nthan yesterday.';

  @override
  String get workoutProgramRunTitle => 'Running';

  @override
  String get workoutProgramRunSubtitle => 'Focused\ncardio';

  @override
  String get workoutProgramGymTitle => 'Gym';

  @override
  String get workoutProgramGymSubtitle => 'Build muscle';

  @override
  String get workoutProgramYogaTitle => 'Yoga';

  @override
  String get workoutProgramYogaSubtitle => 'Relax your mind';

  @override
  String get workoutProgramCyclingTitle => 'Cycling';

  @override
  String get workoutProgramCyclingSubtitle => 'Effective fat\nburn';

  @override
  String get workoutHistoryRunName => 'Running';

  @override
  String get workoutHistoryDate1 => '14 May, 2024';

  @override
  String get workoutHistoryDuration1 => '45 min';

  @override
  String get workoutHistoryGymName => 'Gym';

  @override
  String get workoutHistoryDate2 => '12 May, 2024';

  @override
  String get workoutHistoryDuration2 => '60 min';

  @override
  String get authErrorInvalidEmailFormat => 'Email format is invalid.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorUserNotFound => 'Account not found.';

  @override
  String get authErrorWrongPassword => 'Incorrect password.';

  @override
  String get authErrorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse => 'This email is already in use.';

  @override
  String get authErrorOperationNotAllowed => 'Sign-in is not enabled.';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak (at least 6 characters).';

  @override
  String get authErrorTooManyRequests =>
      'Too many requests. Please try again later.';

  @override
  String get authErrorInvalidCredential =>
      'The login credential is incorrect or has expired.';

  @override
  String get authErrorEmailNotVerified =>
      'Your email is not verified yet. Please verify your email before signing in.';

  @override
  String get authErrorEmailNotVerifiedResent =>
      'Your email is not verified. We have sent another verification email to your inbox.';

  @override
  String authErrorEmailNotVerifiedCooldown(int seconds) {
    return 'Your email is not verified. Please wait $seconds seconds before requesting another verification email.';
  }

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorValidEmailPassword =>
      'Please enter a valid email and password.';

  @override
  String get authErrorCompleteInfo =>
      'Please fill all required information with a valid email.';

  @override
  String get authErrorValidEmail => 'Please enter a valid email.';

  @override
  String get authErrorGoogleSupportedOnly =>
      'Google Sign-In currently supports Android/iOS/Web only.';

  @override
  String get authErrorGoogleNoIdToken =>
      'Could not obtain Google ID token. Please try again.';

  @override
  String get authErrorGoogleConfig =>
      'Google Sign-In configuration error (typically missing SHA1/SHA256 or OAuth client in Firebase).';

  @override
  String get authErrorGoogleCanceled => 'Google sign-in was canceled.';

  @override
  String get authErrorGoogleUiUnavailable =>
      'Cannot open Google sign-in UI. Please try again.';

  @override
  String authErrorGoogleGeneral(Object details) {
    return 'Google sign-in failed: $details';
  }

  @override
  String get authErrorGoogleUnsupportedPlatform =>
      'Google Sign-In is not supported on this platform yet.';

  @override
  String get authErrorGoogleShaMismatch =>
      'Google Sign-In was rejected due to SHA1/SHA256 mismatch in Firebase.';

  @override
  String get authErrorAnonymous => 'Anonymous sign-in failed.';

  @override
  String get authErrorUserMissing => 'User not found.';

  @override
  String get authErrorResendVerificationFailed =>
      'Failed to resend verification email.';

  @override
  String get authErrorResendVerificationGeneric =>
      'An error occurred while resending verification email.';

  @override
  String get authErrorUpdateProfileFailed => 'Failed to update profile.';

  @override
  String get authErrorUpdateProfileGeneric =>
      'An error occurred while updating profile.';

  @override
  String get authErrorDeleteRequiresRelogin =>
      'Please sign in again before deleting your account.';

  @override
  String get authErrorDeleteFailed => 'Failed to delete account.';

  @override
  String get authErrorDeleteGeneric =>
      'An error occurred while deleting account.';

  @override
  String authLogGoogleSignInException(
      Object code, Object description, Object details) {
    return 'GoogleSignInException code=$code, description=$description, details=$details';
  }

  @override
  String authLogGoogleFirebaseException(Object code, Object message) {
    return 'FirebaseAuthException during Google sign-in: code=$code, message=$message';
  }

  @override
  String authLogGoogleSignInError(Object raw) {
    return 'Google sign-in error: $raw';
  }

  @override
  String trackingLogCloudMergeFailed(Object error) {
    return 'Cloud merge failed: $error';
  }

  @override
  String trackingLogCloudSaveFailed(Object error) {
    return 'Cloud save failed: $error';
  }

  @override
  String trackingLogStepCounterError(Object error) {
    return 'Step counter error: $error';
  }

  @override
  String get trackingLogLocationPermissionDeniedForever =>
      'Location permission denied forever.';

  @override
  String get trackingLogLocationServicesDisabled =>
      'Location services disabled.';

  @override
  String trackingLogLocationStreamError(Object error) {
    return 'Location stream error: $error';
  }

  @override
  String trackingLogAccelerometerError(Object error) {
    return 'Accelerometer error: $error';
  }

  @override
  String get aiPromptRecognizeFood =>
      'Identify this food from the image and return ONLY valid JSON with keys: name, calories, protein, carbs, fat.';

  @override
  String aiLogRecognizeFoodError(Object error) {
    return 'Error recognizing food: $error';
  }

  @override
  String aiPromptWorkoutSuggestions(Object userGoal, Object currentStatus) {
    return 'You are a fitness coach. Suggest a workout plan for goal \"$userGoal\" based on current status \"$currentStatus\".';
  }

  @override
  String get aiCouldNotGenerateSuggestions => 'Could not generate suggestions.';

  @override
  String aiErrorGeneric(Object error) {
    return 'Error: $error';
  }

  @override
  String aiPromptDietRecommendations(
      Object healthCondition, Object preferences) {
    return 'You are a nutritionist. Suggest a diet plan for health condition \"$healthCondition\" and preferences \"$preferences\".';
  }

  @override
  String get aiCouldNotGenerateRecommendations =>
      'Could not generate recommendations.';

  @override
  String get hydrationReminderTitle => 'Time to drink water';

  @override
  String hydrationRecommended(int min, int max) {
    return 'Recommended: $min-$max ml/day';
  }

  @override
  String get hydrationYourRecommendation => 'Your recommendation';

  @override
  String hydrationRemaining(int ml) {
    return 'Remaining today: $ml ml';
  }

  @override
  String get hydrationGoalCompleted => 'Goal completed!';

  @override
  String get hydrationCustomGoal => 'Custom goal';

  @override
  String get hydrationUseRecommendation => 'Use recommendation';

  @override
  String get hydrationSmartMode => 'Smart reminder';

  @override
  String get hydrationManualCap => 'Reminder interval (minutes)';
}
