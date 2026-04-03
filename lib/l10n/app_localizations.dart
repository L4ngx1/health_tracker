import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy Living'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @optionsTitle.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get optionsTitle;

  /// No description provided for @optionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust your experience to fit your routine.'**
  String get optionsSubtitle;

  /// No description provided for @settingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteTitle;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get settingsDeleteConfirm;

  /// No description provided for @darkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeTitle;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Easier on your eyes at night and can save battery.'**
  String get darkModeSubtitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminders for activities and goals.'**
  String get notificationsSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred display language.'**
  String get languageSubtitle;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue tracking and improving your health.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @anonymousLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in anonymously'**
  String get anonymousLogin;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get registerNow;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the healthy living community to track and improve your health every day.'**
  String get registerSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get fullNameRequired;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginNow;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @emailHintGeneral.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHintGeneral;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get validEmailRequired;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'A password reset link has been sent if your email exists in the system (check spam too).'**
  String get resetLinkSent;

  /// No description provided for @unverifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get unverifiedTitle;

  /// No description provided for @unverifiedInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please check your email and follow the instructions to verify your account.'**
  String get unverifiedInstruction;

  /// No description provided for @sentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Sent to: {email}'**
  String sentToEmail(Object email);

  /// No description provided for @resendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerification;

  /// No description provided for @verifiedCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'I have verified - Check again'**
  String get verifiedCheckAgain;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email has been verified.'**
  String get emailVerifiedSuccess;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Still not verified. Please check your email.'**
  String get emailNotVerifiedYet;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get profileScreenTitle;

  /// No description provided for @anonymousAccount.
  ///
  /// In en, this message translates to:
  /// **'Anonymous account'**
  String get anonymousAccount;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @emailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get emailUnverified;

  /// No description provided for @editProfileDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileDialogTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdateSuccess;

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get accountInfo;

  /// No description provided for @uidPrefix.
  ///
  /// In en, this message translates to:
  /// **'UID: {uid}'**
  String uidPrefix(Object uid);

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmContent;

  /// No description provided for @workoutScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutScreenTitle;

  /// No description provided for @weekGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s goal'**
  String get weekGoalTitle;

  /// No description provided for @weekGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'4/5 sessions'**
  String get weekGoalProgress;

  /// No description provided for @weekGoalCalories.
  ///
  /// In en, this message translates to:
  /// **'1,240 kcal burned'**
  String get weekGoalCalories;

  /// No description provided for @aiWorkoutSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI workout suggestion'**
  String get aiWorkoutSuggestionTitle;

  /// No description provided for @aiWorkoutSuggestionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to receive a personalized workout plan from AI'**
  String get aiWorkoutSuggestionHint;

  /// No description provided for @aiGeneratePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Generate plan with AI'**
  String get aiGeneratePlanButton;

  /// No description provided for @programModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout modes'**
  String get programModesTitle;

  /// No description provided for @allCaps.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get allCaps;

  /// No description provided for @workoutHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout history'**
  String get workoutHistoryTitle;

  /// No description provided for @nutritionScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition prediction'**
  String get nutritionScreenTitle;

  /// No description provided for @nutritionAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take or upload a food photo so AI can estimate calories'**
  String get nutritionAiSubtitle;

  /// No description provided for @aiReadyTag.
  ///
  /// In en, this message translates to:
  /// **'# AI Ready'**
  String get aiReadyTag;

  /// No description provided for @retakePhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakePhotoTooltip;

  /// No description provided for @capturingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Capturing...'**
  String get capturingPhoto;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get capturePhoto;

  /// No description provided for @pickFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get pickFromLibrary;

  /// No description provided for @tipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tipTitle;

  /// No description provided for @tipDescription.
  ///
  /// In en, this message translates to:
  /// **'Make sure the meal is well-lit so AI can identify ingredients more accurately.'**
  String get tipDescription;

  /// No description provided for @cameraNotFound.
  ///
  /// In en, this message translates to:
  /// **'No camera found on this device.'**
  String get cameraNotFound;

  /// No description provided for @cameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open camera. Please grant permission and try again.'**
  String get cameraOpenFailed;

  /// No description provided for @capturePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot take photo. Please try again.'**
  String get capturePhotoFailed;

  /// No description provided for @galleryAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot access gallery. Please grant permission and try again.'**
  String get galleryAccessFailed;

  /// No description provided for @notesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Health notes'**
  String get notesScreenTitle;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get tapToRecord;

  /// No description provided for @notesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Talk about your health status, diet, or today\'s mood.'**
  String get notesPrompt;

  /// No description provided for @notesContentTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTE CONTENT'**
  String get notesContentTitle;

  /// No description provided for @autoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto detect'**
  String get autoDetect;

  /// No description provided for @notePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Start speaking to see your notes appear here...'**
  String get notePlaceholder;

  /// No description provided for @tagHealth.
  ///
  /// In en, this message translates to:
  /// **'#HEALTH'**
  String get tagHealth;

  /// No description provided for @tagDaily.
  ///
  /// In en, this message translates to:
  /// **'#DAILY'**
  String get tagDaily;

  /// No description provided for @quickMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get quickMealTitle;

  /// No description provided for @quickMealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track nutrition'**
  String get quickMealSubtitle;

  /// No description provided for @quickMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get quickMoodTitle;

  /// No description provided for @quickMoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track feelings'**
  String get quickMoodSubtitle;

  /// No description provided for @journalScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Health journal'**
  String get journalScreenTitle;

  /// No description provided for @journalFrameTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal frame'**
  String get journalFrameTitle;

  /// No description provided for @journalFrameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This page is prepared for you to continue adding notes later.'**
  String get journalFrameSubtitle;

  /// No description provided for @journalSampleEntry.
  ///
  /// In en, this message translates to:
  /// **'Sample note #{index}'**
  String journalSampleEntry(int index);

  /// No description provided for @sleepManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep management'**
  String get sleepManagementTitle;

  /// No description provided for @lastSleepSession.
  ///
  /// In en, this message translates to:
  /// **'Latest sleep session'**
  String get lastSleepSession;

  /// No description provided for @currentStatusSleeping.
  ///
  /// In en, this message translates to:
  /// **'Current status: Sleeping'**
  String get currentStatusSleeping;

  /// No description provided for @currentStatusAwake.
  ///
  /// In en, this message translates to:
  /// **'Current status: Awake'**
  String get currentStatusAwake;

  /// No description provided for @sleepGoalReference.
  ///
  /// In en, this message translates to:
  /// **'Reference goal: 8h per day'**
  String get sleepGoalReference;

  /// No description provided for @sleepHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How sleep is measured'**
  String get sleepHowItWorksTitle;

  /// No description provided for @sleepHowBullet1.
  ///
  /// In en, this message translates to:
  /// **'- Accelerometer data is grouped into 1-minute epochs.'**
  String get sleepHowBullet1;

  /// No description provided for @sleepHowBullet2.
  ///
  /// In en, this message translates to:
  /// **'- Each minute gets an Activity Score from movement threshold hits.'**
  String get sleepHowBullet2;

  /// No description provided for @sleepHowBullet3.
  ///
  /// In en, this message translates to:
  /// **'- A weighted sliding window classifies sleep/awake minute by minute.'**
  String get sleepHowBullet3;

  /// No description provided for @sleepHowBullet4.
  ///
  /// In en, this message translates to:
  /// **'- High step count in current minute favors awake classification.'**
  String get sleepHowBullet4;

  /// No description provided for @sleepHowBullet5.
  ///
  /// In en, this message translates to:
  /// **'- Display has ~1 minute delay because next minute data is needed.'**
  String get sleepHowBullet5;

  /// No description provided for @sleepHowBullet6.
  ///
  /// In en, this message translates to:
  /// **'- This is reference data and may vary if phone is far from the body.'**
  String get sleepHowBullet6;

  /// No description provided for @homePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get homePermissionTitle;

  /// No description provided for @homePermissionContent.
  ///
  /// In en, this message translates to:
  /// **'You permanently denied location permission (Don\'t ask again).\nPlease open Settings and enable Location to calculate distance.'**
  String get homePermissionContent;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @movementGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement goal'**
  String get movementGoalTitle;

  /// No description provided for @todayStats.
  ///
  /// In en, this message translates to:
  /// **'Today: {distance} km â€¢ {steps} steps â€¢ {calories} kcal'**
  String todayStats(Object distance, Object steps, Object calories);

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily goal: {goal} km'**
  String dailyGoalLabel(Object goal);

  /// No description provided for @last7DaysHistory.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7DaysHistory;

  /// No description provided for @statsForDay.
  ///
  /// In en, this message translates to:
  /// **'Stats {day}'**
  String statsForDay(Object day);

  /// No description provided for @goalPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% goal'**
  String goalPercent(int percent);

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get distanceLabel;

  /// No description provided for @stepsLabel.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get stepsLabel;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'CALORIES'**
  String get caloriesLabel;

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save goal'**
  String get saveGoal;

  /// No description provided for @homeTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy with you'**
  String get homeTopTitle;

  /// No description provided for @overviewHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'HEALTH OVERVIEW'**
  String get overviewHealthTitle;

  /// No description provided for @overviewMotivation.
  ///
  /// In en, this message translates to:
  /// **'Great! You\'re\non the right\ntrack.'**
  String get overviewMotivation;

  /// No description provided for @overviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Today you kept a steady routine and slept quite well.'**
  String get overviewSubtitle;

  /// No description provided for @distanceTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE TODAY'**
  String get distanceTodayTitle;

  /// No description provided for @distanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps\n{calories} kcal\nGoal: {goal} km/day'**
  String distanceSubtitle(Object steps, Object calories, Object goal);

  /// No description provided for @sleepRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'LATEST SLEEP'**
  String get sleepRecentTitle;

  /// No description provided for @sleepScoringSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleeping (epoch + weighted sliding window scoring).'**
  String get sleepScoringSleep;

  /// No description provided for @sleepScoringAwake.
  ///
  /// In en, this message translates to:
  /// **'Estimated from acceleration + step counts by minute.'**
  String get sleepScoringAwake;

  /// No description provided for @exploreMore.
  ///
  /// In en, this message translates to:
  /// **'Explore more'**
  String get exploreMore;

  /// No description provided for @trainingLabel.
  ///
  /// In en, this message translates to:
  /// **'WORKOUT'**
  String get trainingLabel;

  /// No description provided for @yogaMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'10-minute\nmorning yoga'**
  String get yogaMorningTitle;

  /// No description provided for @yogaMorningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Relax your body and start the day gently'**
  String get yogaMorningSubtitle;

  /// No description provided for @homeMetricStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'STEPS TODAY'**
  String get homeMetricStepsTitle;

  /// No description provided for @homeMetricStepsUnit.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get homeMetricStepsUnit;

  /// No description provided for @homeMetricStepsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'321 kcal\nburned'**
  String get homeMetricStepsSubtitle;

  /// No description provided for @homeMetricWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'WATER INTAKE'**
  String get homeMetricWaterTitle;

  /// No description provided for @homeMetricWaterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get homeMetricWaterSubtitle;

  /// No description provided for @homeMetricWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get homeMetricWeightTitle;

  /// No description provided for @homeMetricWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stable\nin the last 7\ndays'**
  String get homeMetricWeightSubtitle;

  /// No description provided for @homeMetricSleepTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'SLEEP TODAY'**
  String get homeMetricSleepTodayTitle;

  /// No description provided for @homeMetricSleepTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quality: Good\nYou slept enough\n35 minutes more\nthan yesterday.'**
  String get homeMetricSleepTodaySubtitle;

  /// No description provided for @workoutProgramRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get workoutProgramRunTitle;

  /// No description provided for @workoutProgramRunSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Focused\ncardio'**
  String get workoutProgramRunSubtitle;

  /// No description provided for @workoutProgramGymTitle.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get workoutProgramGymTitle;

  /// No description provided for @workoutProgramGymSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get workoutProgramGymSubtitle;

  /// No description provided for @workoutProgramYogaTitle.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get workoutProgramYogaTitle;

  /// No description provided for @workoutProgramYogaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Relax your mind'**
  String get workoutProgramYogaSubtitle;

  /// No description provided for @workoutProgramCyclingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get workoutProgramCyclingTitle;

  /// No description provided for @workoutProgramCyclingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Effective fat\nburn'**
  String get workoutProgramCyclingSubtitle;

  /// No description provided for @workoutHistoryRunName.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get workoutHistoryRunName;

  /// No description provided for @workoutHistoryDate1.
  ///
  /// In en, this message translates to:
  /// **'14 May, 2024'**
  String get workoutHistoryDate1;

  /// No description provided for @workoutHistoryDuration1.
  ///
  /// In en, this message translates to:
  /// **'45 min'**
  String get workoutHistoryDuration1;

  /// No description provided for @workoutHistoryGymName.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get workoutHistoryGymName;

  /// No description provided for @workoutHistoryDate2.
  ///
  /// In en, this message translates to:
  /// **'12 May, 2024'**
  String get workoutHistoryDate2;

  /// No description provided for @workoutHistoryDuration2.
  ///
  /// In en, this message translates to:
  /// **'60 min'**
  String get workoutHistoryDuration2;

  /// No description provided for @authErrorInvalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Email format is invalid.'**
  String get authErrorInvalidEmailFormat;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not enabled.'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (at least 6 characters).'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorValidEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email and password.'**
  String get authErrorValidEmailPassword;

  /// No description provided for @authErrorCompleteInfo.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required information with a valid email.'**
  String get authErrorCompleteInfo;

  /// No description provided for @authErrorValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get authErrorValidEmail;

  /// No description provided for @authErrorGoogleSupportedOnly.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In currently supports Android/iOS/Web only.'**
  String get authErrorGoogleSupportedOnly;

  /// No description provided for @authErrorGoogleNoIdToken.
  ///
  /// In en, this message translates to:
  /// **'Could not obtain Google ID token. Please try again.'**
  String get authErrorGoogleNoIdToken;

  /// No description provided for @authErrorGoogleConfig.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In configuration error (typically missing SHA1/SHA256 or OAuth client in Firebase).'**
  String get authErrorGoogleConfig;

  /// No description provided for @authErrorGoogleCanceled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was canceled.'**
  String get authErrorGoogleCanceled;

  /// No description provided for @authErrorGoogleUiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cannot open Google sign-in UI. Please try again.'**
  String get authErrorGoogleUiUnavailable;

  /// No description provided for @authErrorGoogleGeneral.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {details}'**
  String authErrorGoogleGeneral(Object details);

  /// No description provided for @authErrorGoogleUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not supported on this platform yet.'**
  String get authErrorGoogleUnsupportedPlatform;

  /// No description provided for @authErrorGoogleShaMismatch.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In was rejected due to SHA1/SHA256 mismatch in Firebase.'**
  String get authErrorGoogleShaMismatch;

  /// No description provided for @authErrorAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous sign-in failed.'**
  String get authErrorAnonymous;

  /// No description provided for @authErrorUserMissing.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get authErrorUserMissing;

  /// No description provided for @authErrorResendVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend verification email.'**
  String get authErrorResendVerificationFailed;

  /// No description provided for @authErrorResendVerificationGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while resending verification email.'**
  String get authErrorResendVerificationGeneric;

  /// No description provided for @authErrorUpdateProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile.'**
  String get authErrorUpdateProfileFailed;

  /// No description provided for @authErrorUpdateProfileGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while updating profile.'**
  String get authErrorUpdateProfileGeneric;

  /// No description provided for @authErrorDeleteRequiresRelogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again before deleting your account.'**
  String get authErrorDeleteRequiresRelogin;

  /// No description provided for @authErrorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account.'**
  String get authErrorDeleteFailed;

  /// No description provided for @authErrorDeleteGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting account.'**
  String get authErrorDeleteGeneric;

  /// No description provided for @authLogGoogleSignInException.
  ///
  /// In en, this message translates to:
  /// **'GoogleSignInException code={code}, description={description}, details={details}'**
  String authLogGoogleSignInException(
      Object code, Object description, Object details);

  /// No description provided for @authLogGoogleFirebaseException.
  ///
  /// In en, this message translates to:
  /// **'FirebaseAuthException during Google sign-in: code={code}, message={message}'**
  String authLogGoogleFirebaseException(Object code, Object message);

  /// No description provided for @authLogGoogleSignInError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in error: {raw}'**
  String authLogGoogleSignInError(Object raw);

  /// No description provided for @trackingLogCloudMergeFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud merge failed: {error}'**
  String trackingLogCloudMergeFailed(Object error);

  /// No description provided for @trackingLogCloudSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud save failed: {error}'**
  String trackingLogCloudSaveFailed(Object error);

  /// No description provided for @trackingLogStepCounterError.
  ///
  /// In en, this message translates to:
  /// **'Step counter error: {error}'**
  String trackingLogStepCounterError(Object error);

  /// No description provided for @trackingLogLocationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied forever.'**
  String get trackingLogLocationPermissionDeniedForever;

  /// No description provided for @trackingLogLocationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled.'**
  String get trackingLogLocationServicesDisabled;

  /// No description provided for @trackingLogLocationStreamError.
  ///
  /// In en, this message translates to:
  /// **'Location stream error: {error}'**
  String trackingLogLocationStreamError(Object error);

  /// No description provided for @trackingLogAccelerometerError.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer error: {error}'**
  String trackingLogAccelerometerError(Object error);

  /// No description provided for @aiPromptRecognizeFood.
  ///
  /// In en, this message translates to:
  /// **'Identify this food from the image and return ONLY valid JSON with keys: name, calories, protein, carbs, fat.'**
  String get aiPromptRecognizeFood;

  /// No description provided for @aiLogRecognizeFoodError.
  ///
  /// In en, this message translates to:
  /// **'Error recognizing food: {error}'**
  String aiLogRecognizeFoodError(Object error);

  /// No description provided for @aiPromptWorkoutSuggestions.
  ///
  /// In en, this message translates to:
  /// **'You are a fitness coach. Suggest a workout plan for goal \"{userGoal}\" based on current status \"{currentStatus}\".'**
  String aiPromptWorkoutSuggestions(Object userGoal, Object currentStatus);

  /// No description provided for @aiCouldNotGenerateSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Could not generate suggestions.'**
  String get aiCouldNotGenerateSuggestions;

  /// No description provided for @aiErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String aiErrorGeneric(Object error);

  /// No description provided for @aiPromptDietRecommendations.
  ///
  /// In en, this message translates to:
  /// **'You are a nutritionist. Suggest a diet plan for health condition \"{healthCondition}\" and preferences \"{preferences}\".'**
  String aiPromptDietRecommendations(
      Object healthCondition, Object preferences);

  /// No description provided for @aiCouldNotGenerateRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Could not generate recommendations.'**
  String get aiCouldNotGenerateRecommendations;

  /// No description provided for @hydrationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to drink water'**
  String get hydrationReminderTitle;

  /// No description provided for @hydrationRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended: {min}-{max} ml/day'**
  String hydrationRecommended(int min, int max);

  /// No description provided for @hydrationYourRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your recommendation'**
  String get hydrationYourRecommendation;

  /// No description provided for @hydrationRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining today: {ml} ml'**
  String hydrationRemaining(int ml);

  /// No description provided for @hydrationGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed!'**
  String get hydrationGoalCompleted;

  /// No description provided for @hydrationCustomGoal.
  ///
  /// In en, this message translates to:
  /// **'Custom goal'**
  String get hydrationCustomGoal;

  /// No description provided for @hydrationUseRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Use recommendation'**
  String get hydrationUseRecommendation;

  /// No description provided for @hydrationSmartMode.
  ///
  /// In en, this message translates to:
  /// **'Smart reminder'**
  String get hydrationSmartMode;

  /// No description provided for @hydrationManualCap.
  ///
  /// In en, this message translates to:
  /// **'Reminder interval (minutes)'**
  String get hydrationManualCap;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
