import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../repositories/hotel_repository.dart';
import 'view_state.dart';

/// Loads the full hotel (with rooms). Starts from the list summary so the
/// header can render instantly while rooms load.
class HotelDetailsProvider extends ChangeNotifier {
  HotelDetailsProvider(this._repo, this.hotel);
  final HotelRepository _repo;

  Hotel hotel;
  ViewState state = ViewState.idle;
  String? error;

  Future<void> load() async {
    state = ViewState.loading;
    error = null;
    notifyListeners();
    try {
      hotel = await _repo.getHotel(hotel.id);
      state = ViewState.success;
    } catch (e) {
      error = errorMessage(e);
      state = ViewState.error;
    }
    notifyListeners();
  }
}
