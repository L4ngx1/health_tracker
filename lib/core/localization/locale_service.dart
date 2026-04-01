import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const _prefKey = 'language';

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('vi'));

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefKey) ?? 'vi';
    locale.value = _normalize(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
    locale.value = _normalize(languageCode);
  }

  Locale _normalize(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en');
      case 'vi':
      default:
        return const Locale('vi');
    }
  }
}
