import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../repositories/hotel_repository.dart';
import 'view_state.dart';
import '../providers/view_state.dart';

class BookingsProvider extends ChangeNotifier {
  BookingsProvider(this._repo);
  final HotelRepository _repo;

  List<Booking> bookings = [];
  ViewState state = ViewState.idle;
  String? error;
  final Set<String> cancelling = {};

  List<Booking> get upcoming => bookings.where((b) => b.isUpcoming).toList()
    ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
  List<Booking> get past => bookings.where((b) => b.isPast).toList();
  List<Booking> get cancelled => bookings.where((b) => b.isCancelled).toList();

  void addBooking(Booking booking) {
    bookings = [
      booking,
      ...bookings.where((b) => b.id != booking.id),
    ];

    state = ViewState.success;
    error = null;
    notifyListeners();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      state = ViewState.loading;
      error = null;
      notifyListeners();
    }
    try {
      bookings = await _repo.getBookings();
      state = ViewState.success;
    } catch (e) {
      if (!silent || bookings.isEmpty) {
        error = errorMessage(e);
        state = ViewState.error;
      }
    }
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> cancel(String id) async {
    cancelling.add(id);
    notifyListeners();
    try {
      final updated = await _repo.cancelBooking(id);
      bookings = [for (final b in bookings) b.id == id ? updated : b];
      return null;
    } catch (e) {
      return errorMessage(e);
    } finally {
      cancelling.remove(id);
      notifyListeners();
    }
  }
}
