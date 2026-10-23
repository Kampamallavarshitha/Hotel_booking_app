import 'package:flutter/foundation.dart';

/// Holds the selected bottom-nav tab so any screen can switch tabs.
class NavProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void go(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}
