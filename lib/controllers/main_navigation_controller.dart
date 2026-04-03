import 'package:flutter/material.dart';

class MainNavigationController extends ChangeNotifier {
  MainNavigationController._internal();

  static final MainNavigationController _instance =
      MainNavigationController._internal();

  factory MainNavigationController() => _instance;

  int _index = 0;

  int get index => _index;

  void setIndex(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }
}
