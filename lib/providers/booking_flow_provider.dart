import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../models/booking.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../repositories/hotel_repository.dart';
import 'view_state.dart';

/// State for one booking attempt: dates, guests, room choice, live availability
/// and submission. Created per booking screen, disposed when it closes.
class BookingFlowProvider extends ChangeNotifier {
  BookingFlowProvider(this._repo, this.hotel, {String? initialRoomId}) : selectedRoomId = initialRoomId {
    checkIn = today().add(const Duration(days: 1));
    checkOut = today().add(const Duration(days: 3));
  }

  static const double taxRate = 0.12;
  static const int maxGuests = 6;

  final HotelRepository _repo;
  final Hotel hotel;

  late DateTime checkIn;
  late DateTime checkOut;
  int guests = 2;
  String? selectedRoomId;

  List<Room> rooms = [];
  ViewState availability = ViewState.idle;
  String? availabilityError;

  bool submitting = false;
  String? submitError;
  int _requestId = 0;

  int get nights => checkOut.difference(checkIn).inDays;

  Room? get selectedRoom {
    for (final r in rooms) {
      if (r.id == selectedRoomId) return r;
    }
    return null;
  }

  bool fits(Room r) => r.capacity >= guests;
  bool bookable(Room r) => (r.available ?? 0) > 0 && fits(r);

  double get subtotal => (selectedRoom?.pricePerNight ?? 0) * nights;
  double get taxes => (subtotal * taxRate).roundToDouble();
  double get grandTotal => subtotal + taxes;

  bool get canSubmit => selectedRoom != null && bookable(selectedRoom!) && !submitting && availability == ViewState.success;

  Future<void> checkAvailability() async {
    final id = ++_requestId;
    availability = ViewState.loading;
    availabilityError = null;
    notifyListeners();
    try {
      final result = await _repo.getAvailability(
        hotelId: hotel.id,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
      );
      if (id != _requestId) return;
      rooms = result;
      availability = ViewState.success;
      _ensureValidSelection();
    } catch (e) {
      if (id != _requestId) return;
      availabilityError = errorMessage(e);
      availability = ViewState.error;
    }
    notifyListeners();
  }

  /// Keep the chosen room if it's still bookable, otherwise pick the first that is.
  void _ensureValidSelection() {
    final current = selectedRoom;
    if (current != null && bookable(current)) return;
    for (final r in rooms) {
      if (bookable(r)) {
        selectedRoomId = r.id;
        return;
      }
    }
    selectedRoomId = current?.id ?? (rooms.isNotEmpty ? rooms.first.id : null);
  }

  void setDates(DateTime start, DateTime end) {
    checkIn = start;
    checkOut = end.isAfter(start) ? end : start.add(const Duration(days: 1));
    checkAvailability();
  }

  void setGuests(int n) {
    if (n < 1 || n > maxGuests || n == guests) return;
    guests = n;
    _ensureValidSelection();
    notifyListeners();
    checkAvailability();
  }

  void selectRoom(String id) {
    selectedRoomId = id;
    notifyListeners();
  }

  /// Returns the created booking, or null (see [submitError]).
  Future<Booking?> submit({
    required String name,
    required String email,
    required String phone,
    String notes = '',
  }) async {
    final room = selectedRoom;
    if (room == null) return null;
    submitting = true;
    submitError = null;
    notifyListeners();
    try {
      final booking = await _repo.createBooking(
        hotelId: hotel.id,
        roomId: room.id,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        guestName: name,
        email: email,
        phone: phone,
        notes: notes,
      );
      submitting = false;
      notifyListeners();
      return booking;
    } catch (e) {
      submitError = errorMessage(e);
      submitting = false;
      notifyListeners();
      // Room may have just sold out: refresh so the UI reflects reality.
      checkAvailability();
      return null;
    }
  }
}
