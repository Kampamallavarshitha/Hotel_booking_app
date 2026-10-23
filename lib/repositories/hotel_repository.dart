import '../core/api/api_client.dart';
import '../core/format.dart';
import '../models/booking.dart';
import '../models/hotel.dart';
import '../models/room.dart';

/// Single data-access point for the UI layer. Turns JSON from [ApiClient]
/// into typed models; providers never see raw maps.
class HotelRepository {
  final ApiClient api;
  const HotelRepository(this.api);

  List<Map<String, dynamic>> _list(Map<String, dynamic> res) => List<Map<String, dynamic>>.from(res['data']);

  Future<List<Hotel>> getHotels(HotelFilters filters) async {
    final res = await api.get('/hotels', query: filters.toQuery());
    return _list(res).map(Hotel.fromJson).toList();
  }

  Future<Hotel> getHotel(String id) async {
    final res = await api.get('/hotels/$id');
    return Hotel.fromJson(res['data']);
  }

  Future<List<Room>> getAvailability({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    final res = await api.get('/hotels/$hotelId/availability', query: {
      'checkIn': isoDate(checkIn),
      'checkOut': isoDate(checkOut),
      'guests': '$guests',
    });
    return List<Map<String, dynamic>>.from(res['data']['rooms']).map(Room.fromJson).toList();
  }

  Future<List<Booking>> getBookings() async {
    final res = await api.get('/bookings');
    return _list(res).map(Booking.fromJson).toList();
  }

  Future<Booking> createBooking({
    required String hotelId,
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String email,
    required String phone,
    String notes = '',
  }) async {
    final res = await api.post('/bookings', body: {
      'hotelId': hotelId,
      'roomId': roomId,
      'checkIn': isoDate(checkIn),
      'checkOut': isoDate(checkOut),
      'guests': guests,
      'guestName': guestName,
      'email': email,
      'phone': phone,
      'notes': notes,
    });
    return Booking.fromJson(res['data']);
  }

  Future<Booking> cancelBooking(String id) async {
    final res = await api.post('/bookings/$id/cancel');
    return Booking.fromJson(res['data']);
  }

  Future<UserProfile> getProfile() async => UserProfile.fromJson((await api.get('/profile'))['data']);

  Future<UserProfile> updateProfile(UserProfile p) async {
    final res = await api.put('/profile', body: {'name': p.name, 'email': p.email, 'phone': p.phone});
    return UserProfile.fromJson(res['data']);
  }
}
