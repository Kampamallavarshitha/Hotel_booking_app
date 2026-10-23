import 'dart:convert';
import 'dart:math';

import '../format.dart';
import '../validators.dart';
import 'api_client.dart';
import 'mock_data.dart';

/// In-memory fake backend that behaves like a REST API:
/// routing, query parsing, validation, status codes, latency and JSON envelope.
/// Full contract: docs/API.md
class MockApiClient implements ApiClient {
  MockApiClient({this.latency = const Duration(milliseconds: 700)}) {
    _seedBookings();
  }

  /// Shared instance used by the app.
  static final MockApiClient instance = MockApiClient();

  final Duration latency;

  /// When true every request fails with 503 (toggle in Profile → Developer options).
  bool simulateFailure = false;

  final List<Map<String, dynamic>> _bookings = [];
  int _seq = 1003;
  Map<String, dynamic> _profile = {
    'name': 'Varshitha Kampalla',
    'email': 'varshitha@example.com',
    'phone': '9876543210',
  };

  // ------------------------------------------------------------- public API
  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, String> query = const {}}) =>
      _handle('GET', path, query: query);

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _handle('POST', path, body: body);

  @override
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _handle('PUT', path, body: body);

  // ---------------------------------------------------------------- router
  Future<Map<String, dynamic>> _handle(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
  }) async {
    await Future.delayed(latency);
    if (simulateFailure) {
      throw const ApiException(503, 'Server unavailable. Check your connection and try again.');
    }

    final seg = path.split('/').where((s) => s.isNotEmpty).toList();
    Object? data;
    Map<String, dynamic> meta = {};

    if (method == 'GET' && _is(seg, ['hotels'])) {
      final list = _searchHotels(query);
      data = list;
      meta = {'total': list.length};
    } else if (method == 'GET' && _is(seg, ['hotels', '*'])) {
      data = _hotelById(seg[1]);
    } else if (method == 'GET' && _is(seg, ['hotels', '*', 'availability'])) {
      data = _availability(seg[1], query);
    } else if (method == 'GET' && _is(seg, ['bookings'])) {
      final list = [..._bookings]..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      data = list;
      meta = {'total': list.length};
    } else if (method == 'POST' && _is(seg, ['bookings'])) {
      data = _createBooking(body ?? {});
    } else if (method == 'POST' && _is(seg, ['bookings', '*', 'cancel'])) {
      data = _cancelBooking(seg[1]);
    } else if (method == 'GET' && _is(seg, ['profile'])) {
      data = _profile;
    } else if (method == 'PUT' && _is(seg, ['profile'])) {
      data = _updateProfile(body ?? {});
    } else {
      throw ApiException(404, 'Route not found: $method $path');
    }

    // Round-trip through JSON so the app only ever sees real JSON types.
    return jsonDecode(jsonEncode({'success': true, 'data': data, 'meta': meta})) as Map<String, dynamic>;
  }

  bool _is(List<String> seg, List<String> pattern) {
    if (seg.length != pattern.length) return false;
    for (var i = 0; i < seg.length; i++) {
      if (pattern[i] != '*' && pattern[i] != seg[i]) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------- hotels
  List<Map<String, dynamic>> _searchHotels(Map<String, String> q) {
    final text = (q['q'] ?? '').trim().toLowerCase();
    final minPrice = double.tryParse(q['minPrice'] ?? '') ?? 0;
    final maxPrice = double.tryParse(q['maxPrice'] ?? '') ?? double.infinity;
    final minRating = double.tryParse(q['minRating'] ?? '') ?? 0;
    final amenities = (q['amenities'] ?? '').split(',').where((e) => e.isNotEmpty).toList();

    final result = seedHotels.where((h) {
      final haystack = '${h['name']} ${h['city']} ${h['state']}'.toLowerCase();
      final price = (h['pricePerNight'] as num).toDouble();
      return (text.isEmpty || haystack.contains(text)) &&
          price >= minPrice &&
          price <= maxPrice &&
          (h['rating'] as num) >= minRating &&
          (h['amenities'] as List).toSet().containsAll(amenities);
    }).toList();

    switch (q['sort']) {
      case 'price_asc':
        result.sort((a, b) => (a['pricePerNight'] as num).compareTo(b['pricePerNight'] as num));
      case 'price_desc':
        result.sort((a, b) => (b['pricePerNight'] as num).compareTo(a['pricePerNight'] as num));
      case 'rating':
        result.sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
    }
    // List responses are summaries: no rooms.
    return result.map((h) => Map<String, dynamic>.of(h)..remove('rooms')).toList();
  }

  Map<String, dynamic> _rawHotel(String id) {
    for (final h in seedHotels) {
      if (h['id'] == id) return h;
    }
    throw ApiException(404, 'Hotel $id not found');
  }

  Map<String, dynamic> _hotelById(String id) => _rawHotel(id);

  // ---------------------------------------------------------- availability
  ({DateTime checkIn, DateTime checkOut}) _parseDates(Map<String, dynamic> src) {
    final ci = DateTime.tryParse('${src['checkIn']}');
    final co = DateTime.tryParse('${src['checkOut']}');
    if (ci == null || co == null) throw const ApiException(422, 'checkIn and checkOut must be dates in YYYY-MM-DD format');
    if (ci.isBefore(today())) throw const ApiException(422, 'Check-in date cannot be in the past');
    if (!co.isAfter(ci)) throw const ApiException(422, 'Check-out must be after check-in');
    return (checkIn: ci, checkOut: co);
  }

  /// Rooms left for a stay = total − simulated walk-in demand − overlapping bookings.
  /// The simulated demand is deterministic per room + check-in day, so some
  /// dates look busy and the "sold out" state can be demoed.
  int _roomsLeft(Map<String, dynamic> hotel, Map<String, dynamic> room, DateTime ci, DateTime co) {
    final seed = (room['id'] as String).codeUnits.fold<int>(0, (a, b) => a + b);
    final demand = (seed + ci.day) % 3;
    final booked = _bookings.where((b) {
      return b['hotelId'] == hotel['id'] &&
          b['roomId'] == room['id'] &&
          (b['status'] == 'pending' || b['status'] == 'confirmed') &&
          DateTime.parse(b['checkIn']).isBefore(co) &&
          DateTime.parse(b['checkOut']).isAfter(ci);
    }).length;
    return max(0, (room['totalRooms'] as int) - demand - booked);
  }

  Map<String, dynamic> _availability(String hotelId, Map<String, String> q) {
    final hotel = _rawHotel(hotelId);
    final d = _parseDates(q);
    final guests = int.tryParse(q['guests'] ?? '') ?? 1;
    final nights = d.checkOut.difference(d.checkIn).inDays;
    final rooms = (hotel['rooms'] as List).cast<Map<String, dynamic>>().map((r) => {
          ...r,
          'available': _roomsLeft(hotel, r, d.checkIn, d.checkOut),
        });
    return {
      'hotelId': hotelId,
      'checkIn': isoDate(d.checkIn),
      'checkOut': isoDate(d.checkOut),
      'guests': guests,
      'nights': nights,
      'rooms': rooms.toList(),
    };
  }

  // -------------------------------------------------------------- bookings
  Map<String, dynamic> _createBooking(Map<String, dynamic> b) {
    for (final f in ['hotelId', 'roomId', 'checkIn', 'checkOut', 'guests', 'guestName', 'email', 'phone']) {
      if (b[f] == null || '${b[f]}'.trim().isEmpty) throw ApiException(422, 'Missing required field: $f');
    }
    final hotel = _rawHotel(b['hotelId']);
    final room = (hotel['rooms'] as List).cast<Map<String, dynamic>>().firstWhere(
          (r) => r['id'] == b['roomId'],
          orElse: () => throw ApiException(404, 'Room ${b['roomId']} not found'),
        );
    final d = _parseDates(b);
    final guests = (b['guests'] as num).toInt();
    if (guests < 1 || guests > (room['capacity'] as int)) {
      throw ApiException(422, '${room['name']} sleeps up to ${room['capacity']} guests');
    }
    if (Validators.email(b['email']) != null) throw const ApiException(422, 'Invalid email address');
    if (Validators.phone(b['phone']) != null) throw const ApiException(422, 'Invalid phone number');
    if (_roomsLeft(hotel, room, d.checkIn, d.checkOut) < 1) {
      throw const ApiException(409, 'This room is sold out for the selected dates');
    }

    final nights = d.checkOut.difference(d.checkIn).inDays;
    final subtotal = (room['pricePerNight'] as int) * nights;
    final taxes = (subtotal * 0.12).round();
    final booking = {
      'id': 'BK${_seq++}',
      'hotelId': hotel['id'],
      'hotelName': hotel['name'],
      'hotelImage': (hotel['images'] as List).first,
      'city': hotel['city'],
      'roomId': room['id'],
      'roomName': room['name'],
      'checkIn': isoDate(d.checkIn),
      'checkOut': isoDate(d.checkOut),
      'nights': nights,
      'guests': guests,
      'guestName': '${b['guestName']}'.trim(),
      'email': '${b['email']}'.trim(),
      'phone': '${b['phone']}'.trim(),
      'notes': '${b['notes'] ?? ''}'.trim(),
      'subtotal': subtotal,
      'taxes': taxes,
      'total': subtotal + taxes,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _bookings.add(booking);
    return booking;
  }

  Map<String, dynamic> _cancelBooking(String id) {
    final i = _bookings.indexWhere((b) => b['id'] == id);
    if (i < 0) throw ApiException(404, 'Booking $id not found');
    final status = _bookings[i]['status'];
    if (status == 'cancelled') throw const ApiException(409, 'This booking is already cancelled');
    if (status == 'completed') throw const ApiException(409, 'Completed stays cannot be cancelled');
    _bookings[i] = {..._bookings[i], 'status': 'cancelled'};
    return _bookings[i];
  }

  void _seedBookings() {
    Map<String, dynamic> make(String id, String hotelId, String roomId, int startOffset, int nights, String status, int guests) {
      final h = seedHotels.firstWhere((e) => e['id'] == hotelId);
      final r = (h['rooms'] as List).cast<Map<String, dynamic>>().firstWhere((e) => e['id'] == roomId);
      final ci = today().add(Duration(days: startOffset));
      final co = ci.add(Duration(days: nights));
      final subtotal = (r['pricePerNight'] as int) * nights;
      final taxes = (subtotal * 0.12).round();
      return {
        'id': id,
        'hotelId': hotelId,
        'hotelName': h['name'],
        'hotelImage': (h['images'] as List).first,
        'city': h['city'],
        'roomId': roomId,
        'roomName': r['name'],
        'checkIn': isoDate(ci),
        'checkOut': isoDate(co),
        'nights': nights,
        'guests': guests,
        'guestName': _profile['name'],
        'email': _profile['email'],
        'phone': _profile['phone'],
        'notes': '',
        'subtotal': subtotal,
        'taxes': taxes,
        'total': subtotal + taxes,
        'status': status,
        'createdAt': today().add(Duration(days: startOffset - 14)).toIso8601String(),
      };
    }

    _bookings.addAll([
      make('BK1001', 'h2', 'h2r1', -40, 2, 'completed', 2),
      make('BK1002', 'h5', 'h5r1', 21, 3, 'confirmed', 2),
    ]);
  }

  // --------------------------------------------------------------- profile
  Map<String, dynamic> _updateProfile(Map<String, dynamic> b) {
    if (Validators.name(b['name']) != null) throw const ApiException(422, 'Enter a valid name');
    if (Validators.email(b['email']) != null) throw const ApiException(422, 'Invalid email address');
    if (Validators.phone(b['phone']) != null) throw const ApiException(422, 'Invalid phone number');
    _profile = {'name': '${b['name']}'.trim(), 'email': '${b['email']}'.trim(), 'phone': '${b['phone']}'.trim()};
    return _profile;
  }
}
