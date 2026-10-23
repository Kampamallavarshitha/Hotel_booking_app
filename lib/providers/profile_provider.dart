import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../repositories/hotel_repository.dart';
import 'view_state.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._repo);
  final HotelRepository _repo;

  UserProfile? profile;
  ViewState state = ViewState.idle;
  String? error;
  bool saving = false;

  Future<void> load() async {
    state = ViewState.loading;
    error = null;
    notifyListeners();
    try {
      profile = await _repo.getProfile();
      state = ViewState.success;
    } catch (e) {
      error = errorMessage(e);
      state = ViewState.error;
    }
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> save(UserProfile updated) async {
    saving = true;
    notifyListeners();
    try {
      profile = await _repo.updateProfile(updated);
      return null;
    } catch (e) {
      return errorMessage(e);
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
