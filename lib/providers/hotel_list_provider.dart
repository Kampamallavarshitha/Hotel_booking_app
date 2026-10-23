import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../repositories/hotel_repository.dart';
import 'view_state.dart';

/// Drives the Explore screen: search text, filters, sorting and the result list.
class HotelListProvider extends ChangeNotifier {
  HotelListProvider(this._repo);
  final HotelRepository _repo;

  List<Hotel> hotels = [];
  HotelFilters filters = const HotelFilters();
  ViewState state = ViewState.idle;
  String? error;

  Timer? _debounce;
  int _requestId = 0; // ignore out-of-order responses

  Future<void> load() async {
    final id = ++_requestId;
    state = ViewState.loading;
    error = null;
    notifyListeners();
    try {
      final result = await _repo.getHotels(filters);
      if (id != _requestId) return;
      hotels = result;
      state = ViewState.success;
    } catch (e) {
      if (id != _requestId) return;
      error = errorMessage(e);
      state = ViewState.error;
    }
    notifyListeners();
  }

  /// Debounced so we don't call the API on every keystroke.
  void setQuery(String q) {
    filters = filters.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  void apply(HotelFilters f) {
    filters = f.copyWith(query: filters.query);
    load();
  }

  void clearFilters() {
    filters = HotelFilters(query: filters.query);
    load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
