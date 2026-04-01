import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class AppStrings {
  AppStrings._();

  static AppLocalizations _l10n(BuildContext context) =>
      AppLocalizations.of(context)!;

  static String settingsTitle(BuildContext context) {
    return _l10n(context).settingsTitle;
  }

  static String optionsTitle(BuildContext context) {
    return _l10n(context).optionsTitle;
  }

  static String optionsSubtitle(BuildContext context) {
    return _l10n(context).optionsSubtitle;
  }

  static String darkModeTitle(BuildContext context) {
    return _l10n(context).darkModeTitle;
  }

  static String darkModeSubtitle(BuildContext context) {
    return _l10n(context).darkModeSubtitle;
  }

  static String notificationsTitle(BuildContext context) {
    return _l10n(context).notificationsTitle;
  }

  static String notificationsSubtitle(BuildContext context) {
    return _l10n(context).notificationsSubtitle;
  }

  static String languageTitle(BuildContext context) {
    return _l10n(context).languageTitle;
  }

  static String languageSubtitle(BuildContext context) {
    return _l10n(context).languageSubtitle;
  }

  static String deleteAccount(BuildContext context) {
    return _l10n(context).deleteAccount;
  }

  static String processing(BuildContext context) {
    return _l10n(context).processing;
  }

  static String appTitle(BuildContext context) {
    return _l10n(context).appTitle;
  }

  static String navHome(BuildContext context) {
    return _l10n(context).navHome;
  }

  static String navWorkout(BuildContext context) {
    return _l10n(context).navWorkout;
  }

  static String navNutrition(BuildContext context) {
    return _l10n(context).navNutrition;
  }

  static String navNotes(BuildContext context) {
    return _l10n(context).navNotes;
  }

  static String navJournal(BuildContext context) {
    return _l10n(context).navJournal;
  }

  static String back(BuildContext context) => _l10n(context).back;
  static String cancel(BuildContext context) => _l10n(context).cancel;
  static String save(BuildContext context) => _l10n(context).save;
  static String send(BuildContext context) => _l10n(context).send;
  static String deleteAction(BuildContext context) =>
      _l10n(context).deleteAction;
  static String logout(BuildContext context) => _l10n(context).logout;
  static String orLabel(BuildContext context) => _l10n(context).orLabel;

  static String settingsDeleteTitle(BuildContext context) =>
      _l10n(context).settingsDeleteTitle;
  static String settingsDeleteConfirm(BuildContext context) =>
      _l10n(context).settingsDeleteConfirm;
  static String languageVietnamese(BuildContext context) =>
      _l10n(context).languageVietnamese;
  static String languageEnglish(BuildContext context) =>
      _l10n(context).languageEnglish;

  static String loginWelcomeBack(BuildContext context) =>
      _l10n(context).loginWelcomeBack;
  static String loginSubtitle(BuildContext context) =>
      _l10n(context).loginSubtitle;
  static String emailLabel(BuildContext context) => _l10n(context).emailLabel;
  static String emailHint(BuildContext context) => _l10n(context).emailHint;
  static String passwordLabel(BuildContext context) =>
      _l10n(context).passwordLabel;
  static String passwordHint(BuildContext context) =>
      _l10n(context).passwordHint;
  static String emailRequired(BuildContext context) =>
      _l10n(context).emailRequired;
  static String emailInvalid(BuildContext context) =>
      _l10n(context).emailInvalid;
  static String passwordRequired(BuildContext context) =>
      _l10n(context).passwordRequired;
  static String passwordTooShort(BuildContext context) =>
      _l10n(context).passwordTooShort;
  static String forgotPassword(BuildContext context) =>
      _l10n(context).forgotPassword;
  static String login(BuildContext context) => _l10n(context).login;
  static String continueWithGoogle(BuildContext context) =>
      _l10n(context).continueWithGoogle;
  static String anonymousLogin(BuildContext context) =>
      _l10n(context).anonymousLogin;
  static String noAccount(BuildContext context) => _l10n(context).noAccount;
  static String registerNow(BuildContext context) => _l10n(context).registerNow;

  static String registerTitle(BuildContext context) =>
      _l10n(context).registerTitle;
  static String registerSubtitle(BuildContext context) =>
      _l10n(context).registerSubtitle;
  static String fullNameLabel(BuildContext context) =>
      _l10n(context).fullNameLabel;
  static String fullNameHint(BuildContext context) =>
      _l10n(context).fullNameHint;
  static String fullNameRequired(BuildContext context) =>
      _l10n(context).fullNameRequired;
  static String confirmPasswordLabel(BuildContext context) =>
      _l10n(context).confirmPasswordLabel;
  static String confirmPasswordHint(BuildContext context) =>
      _l10n(context).confirmPasswordHint;
  static String confirmPasswordRequired(BuildContext context) =>
      _l10n(context).confirmPasswordRequired;
  static String passwordMismatch(BuildContext context) =>
      _l10n(context).passwordMismatch;
  static String register(BuildContext context) => _l10n(context).register;
  static String haveAccount(BuildContext context) => _l10n(context).haveAccount;
  static String loginNow(BuildContext context) => _l10n(context).loginNow;

  static String forgotPasswordTitle(BuildContext context) =>
      _l10n(context).forgotPasswordTitle;
  static String forgotPasswordSubtitle(BuildContext context) =>
      _l10n(context).forgotPasswordSubtitle;
  static String emailHintGeneral(BuildContext context) =>
      _l10n(context).emailHintGeneral;
  static String validEmailRequired(BuildContext context) =>
      _l10n(context).validEmailRequired;
  static String resetLinkSent(BuildContext context) =>
      _l10n(context).resetLinkSent;

  static String unverifiedTitle(BuildContext context) =>
      _l10n(context).unverifiedTitle;
  static String unverifiedInstruction(BuildContext context) =>
      _l10n(context).unverifiedInstruction;
  static String sentToEmail(BuildContext context, String email) =>
      _l10n(context).sentToEmail(email);
  static String resendVerification(BuildContext context) =>
      _l10n(context).resendVerification;
  static String verifiedCheckAgain(BuildContext context) =>
      _l10n(context).verifiedCheckAgain;
  static String emailVerifiedSuccess(BuildContext context) =>
      _l10n(context).emailVerifiedSuccess;
  static String emailNotVerifiedYet(BuildContext context) =>
      _l10n(context).emailNotVerifiedYet;

  static String profileScreenTitle(BuildContext context) =>
      _l10n(context).profileScreenTitle;
  static String anonymousAccount(BuildContext context) =>
      _l10n(context).anonymousAccount;
  static String emailVerified(BuildContext context) =>
      _l10n(context).emailVerified;
  static String emailUnverified(BuildContext context) =>
      _l10n(context).emailUnverified;
  static String editProfileDialogTitle(BuildContext context) =>
      _l10n(context).editProfileDialogTitle;
  static String nameLabel(BuildContext context) => _l10n(context).nameLabel;
  static String profileUpdateSuccess(BuildContext context) =>
      _l10n(context).profileUpdateSuccess;
  static String userFallback(BuildContext context) =>
      _l10n(context).userFallback;
  static String noEmail(BuildContext context) => _l10n(context).noEmail;
  static String editProfile(BuildContext context) => _l10n(context).editProfile;
  static String accountInfo(BuildContext context) => _l10n(context).accountInfo;
  static String uidPrefix(BuildContext context, String uid) =>
      _l10n(context).uidPrefix(uid);
  static String logoutConfirmTitle(BuildContext context) =>
      _l10n(context).logoutConfirmTitle;
  static String logoutConfirmContent(BuildContext context) =>
      _l10n(context).logoutConfirmContent;

  static String workoutScreenTitle(BuildContext context) =>
      _l10n(context).workoutScreenTitle;
  static String weekGoalTitle(BuildContext context) =>
      _l10n(context).weekGoalTitle;
  static String weekGoalProgress(BuildContext context) =>
      _l10n(context).weekGoalProgress;
  static String weekGoalCalories(BuildContext context) =>
      _l10n(context).weekGoalCalories;
  static String aiWorkoutSuggestionTitle(BuildContext context) =>
      _l10n(context).aiWorkoutSuggestionTitle;
  static String aiWorkoutSuggestionHint(BuildContext context) =>
      _l10n(context).aiWorkoutSuggestionHint;
  static String aiGeneratePlanButton(BuildContext context) =>
      _l10n(context).aiGeneratePlanButton;
  static String programModesTitle(BuildContext context) =>
      _l10n(context).programModesTitle;
  static String allCaps(BuildContext context) => _l10n(context).allCaps;
  static String workoutHistoryTitle(BuildContext context) =>
      _l10n(context).workoutHistoryTitle;

  static String nutritionScreenTitle(BuildContext context) =>
      _l10n(context).nutritionScreenTitle;
  static String nutritionAiSubtitle(BuildContext context) =>
      _l10n(context).nutritionAiSubtitle;
  static String aiReadyTag(BuildContext context) => _l10n(context).aiReadyTag;
  static String retakePhotoTooltip(BuildContext context) =>
      _l10n(context).retakePhotoTooltip;
  static String capturingPhoto(BuildContext context) =>
      _l10n(context).capturingPhoto;
  static String capturePhoto(BuildContext context) =>
      _l10n(context).capturePhoto;
  static String pickFromLibrary(BuildContext context) =>
      _l10n(context).pickFromLibrary;
  static String tipTitle(BuildContext context) => _l10n(context).tipTitle;
  static String tipDescription(BuildContext context) =>
      _l10n(context).tipDescription;
  static String cameraNotFound(BuildContext context) =>
      _l10n(context).cameraNotFound;
  static String cameraOpenFailed(BuildContext context) =>
      _l10n(context).cameraOpenFailed;
  static String capturePhotoFailed(BuildContext context) =>
      _l10n(context).capturePhotoFailed;
  static String galleryAccessFailed(BuildContext context) =>
      _l10n(context).galleryAccessFailed;

  static String notesScreenTitle(BuildContext context) =>
      _l10n(context).notesScreenTitle;
  static String tapToRecord(BuildContext context) => _l10n(context).tapToRecord;
  static String notesPrompt(BuildContext context) => _l10n(context).notesPrompt;
  static String notesContentTitle(BuildContext context) =>
      _l10n(context).notesContentTitle;
  static String autoDetect(BuildContext context) => _l10n(context).autoDetect;
  static String notePlaceholder(BuildContext context) =>
      _l10n(context).notePlaceholder;
  static String tagHealth(BuildContext context) => _l10n(context).tagHealth;
  static String tagDaily(BuildContext context) => _l10n(context).tagDaily;
  static String quickMealTitle(BuildContext context) =>
      _l10n(context).quickMealTitle;
  static String quickMealSubtitle(BuildContext context) =>
      _l10n(context).quickMealSubtitle;
  static String quickMoodTitle(BuildContext context) =>
      _l10n(context).quickMoodTitle;
  static String quickMoodSubtitle(BuildContext context) =>
      _l10n(context).quickMoodSubtitle;

  static String journalScreenTitle(BuildContext context) =>
      _l10n(context).journalScreenTitle;
  static String journalFrameTitle(BuildContext context) =>
      _l10n(context).journalFrameTitle;
  static String journalFrameSubtitle(BuildContext context) =>
      _l10n(context).journalFrameSubtitle;
  static String journalSampleEntry(BuildContext context, int index) =>
      _l10n(context).journalSampleEntry(index);

  static String sleepManagementTitle(BuildContext context) =>
      _l10n(context).sleepManagementTitle;
  static String lastSleepSession(BuildContext context) =>
      _l10n(context).lastSleepSession;
  static String currentStatusSleeping(BuildContext context) =>
      _l10n(context).currentStatusSleeping;
  static String currentStatusAwake(BuildContext context) =>
      _l10n(context).currentStatusAwake;
  static String sleepGoalReference(BuildContext context) =>
      _l10n(context).sleepGoalReference;
  static String sleepHowItWorksTitle(BuildContext context) =>
      _l10n(context).sleepHowItWorksTitle;
  static String sleepHowBullet1(BuildContext context) =>
      _l10n(context).sleepHowBullet1;
  static String sleepHowBullet2(BuildContext context) =>
      _l10n(context).sleepHowBullet2;
  static String sleepHowBullet3(BuildContext context) =>
      _l10n(context).sleepHowBullet3;
  static String sleepHowBullet4(BuildContext context) =>
      _l10n(context).sleepHowBullet4;
  static String sleepHowBullet5(BuildContext context) =>
      _l10n(context).sleepHowBullet5;
  static String sleepHowBullet6(BuildContext context) =>
      _l10n(context).sleepHowBullet6;

  static String homePermissionTitle(BuildContext context) =>
      _l10n(context).homePermissionTitle;
  static String homePermissionContent(BuildContext context) =>
      _l10n(context).homePermissionContent;
  static String later(BuildContext context) => _l10n(context).later;
  static String openSettings(BuildContext context) =>
      _l10n(context).openSettings;
  static String movementGoalTitle(BuildContext context) =>
      _l10n(context).movementGoalTitle;
  static String todayStats(
    BuildContext context,
    String distance,
    String steps,
    String calories,
  ) => _l10n(context).todayStats(distance, steps, calories);
  static String dailyGoalLabel(BuildContext context, String goal) =>
      _l10n(context).dailyGoalLabel(goal);
  static String last7DaysHistory(BuildContext context) =>
      _l10n(context).last7DaysHistory;
  static String statsForDay(BuildContext context, String day) =>
      _l10n(context).statsForDay(day);
  static String goalPercent(BuildContext context, int percent) =>
      _l10n(context).goalPercent(percent);
  static String distanceLabel(BuildContext context) =>
      _l10n(context).distanceLabel;
  static String stepsLabel(BuildContext context) => _l10n(context).stepsLabel;
  static String caloriesLabel(BuildContext context) =>
      _l10n(context).caloriesLabel;
  static String saveGoal(BuildContext context) => _l10n(context).saveGoal;
  static String homeTopTitle(BuildContext context) =>
      _l10n(context).homeTopTitle;
  static String overviewHealthTitle(BuildContext context) =>
      _l10n(context).overviewHealthTitle;
  static String overviewMotivation(BuildContext context) =>
      _l10n(context).overviewMotivation;
  static String overviewSubtitle(BuildContext context) =>
      _l10n(context).overviewSubtitle;
  static String distanceTodayTitle(BuildContext context) =>
      _l10n(context).distanceTodayTitle;
  static String distanceSubtitle(
    BuildContext context,
    String steps,
    String calories,
    String goal,
  ) => _l10n(context).distanceSubtitle(steps, calories, goal);
  static String sleepRecentTitle(BuildContext context) =>
      _l10n(context).sleepRecentTitle;
  static String sleepScoringSleep(BuildContext context) =>
      _l10n(context).sleepScoringSleep;
  static String sleepScoringAwake(BuildContext context) =>
      _l10n(context).sleepScoringAwake;
  static String exploreMore(BuildContext context) => _l10n(context).exploreMore;
  static String trainingLabel(BuildContext context) =>
      _l10n(context).trainingLabel;
  static String yogaMorningTitle(BuildContext context) =>
      _l10n(context).yogaMorningTitle;
  static String yogaMorningSubtitle(BuildContext context) =>
      _l10n(context).yogaMorningSubtitle;

  static String homeMetricStepsTitle(BuildContext context) =>
      _l10n(context).homeMetricStepsTitle;
  static String homeMetricStepsUnit(BuildContext context) =>
      _l10n(context).homeMetricStepsUnit;
  static String homeMetricStepsSubtitle(BuildContext context) =>
      _l10n(context).homeMetricStepsSubtitle;
  static String homeMetricWaterTitle(BuildContext context) =>
      _l10n(context).homeMetricWaterTitle;
  static String homeMetricWaterSubtitle(BuildContext context) =>
      _l10n(context).homeMetricWaterSubtitle;
  static String homeMetricWeightTitle(BuildContext context) =>
      _l10n(context).homeMetricWeightTitle;
  static String homeMetricWeightSubtitle(BuildContext context) =>
      _l10n(context).homeMetricWeightSubtitle;
  static String homeMetricSleepTodayTitle(BuildContext context) =>
      _l10n(context).homeMetricSleepTodayTitle;
  static String homeMetricSleepTodaySubtitle(BuildContext context) =>
      _l10n(context).homeMetricSleepTodaySubtitle;

  static String workoutProgramRunTitle(BuildContext context) =>
      _l10n(context).workoutProgramRunTitle;
  static String workoutProgramRunSubtitle(BuildContext context) =>
      _l10n(context).workoutProgramRunSubtitle;
  static String workoutProgramGymTitle(BuildContext context) =>
      _l10n(context).workoutProgramGymTitle;
  static String workoutProgramGymSubtitle(BuildContext context) =>
      _l10n(context).workoutProgramGymSubtitle;
  static String workoutProgramYogaTitle(BuildContext context) =>
      _l10n(context).workoutProgramYogaTitle;
  static String workoutProgramYogaSubtitle(BuildContext context) =>
      _l10n(context).workoutProgramYogaSubtitle;
  static String workoutProgramCyclingTitle(BuildContext context) =>
      _l10n(context).workoutProgramCyclingTitle;
  static String workoutProgramCyclingSubtitle(BuildContext context) =>
      _l10n(context).workoutProgramCyclingSubtitle;

  static String workoutHistoryRunName(BuildContext context) =>
      _l10n(context).workoutHistoryRunName;
  static String workoutHistoryDate1(BuildContext context) =>
      _l10n(context).workoutHistoryDate1;
  static String workoutHistoryDuration1(BuildContext context) =>
      _l10n(context).workoutHistoryDuration1;
  static String workoutHistoryGymName(BuildContext context) =>
      _l10n(context).workoutHistoryGymName;
  static String workoutHistoryDate2(BuildContext context) =>
      _l10n(context).workoutHistoryDate2;
  static String workoutHistoryDuration2(BuildContext context) =>
      _l10n(context).workoutHistoryDuration2;

  static bool isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }
}
