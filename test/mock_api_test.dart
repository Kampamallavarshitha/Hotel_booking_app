import 'package:flutter_test/flutter_test.dart';
import 'package:stayscape/core/api/api_client.dart';
import 'package:stayscape/core/api/mock_api_client.dart';
import 'package:stayscape/core/format.dart';
import 'package:stayscape/models/hotel.dart';
import 'package:stayscape/repositories/hotel_repository.dart';

void main() {
  late HotelRepository repo;

  setUp(() => repo = HotelRepository(MockApiClient(latency: Duration.zero)));

  test('search filters by text, price and amenities', () async {
    final all = await repo.getHotels(const HotelFilters());
    expect(all.length, 8);

    final goa = await repo.getHotels(const HotelFilters(query: 'goa'));
    expect(goa.single.city, 'Calangute');

    final cheap = await repo.getHotels(const HotelFilters(maxPrice: 4000));
    expect(cheap.every((h) => h.pricePerNight <= 4000), isTrue);

    final spa = await repo.getHotels(const HotelFilters(amenities: {'Spa', 'Pool'}));
    expect(spa.every((h) => h.amenities.contains('Spa') && h.amenities.contains('Pool')), isTrue);
  });

  test('sorting by price ascending', () async {
    final list = await repo.getHotels(const HotelFilters(sort: 'price_asc'));
    final prices = list.map((h) => h.pricePerNight).toList();
    expect(prices, [...prices]..sort());
  });

  test('booking reduces availability and rejects bad input', () async {
    final ci = today().add(const Duration(days: 10));
    final co = ci.add(const Duration(days: 2));

    final before = await repo.getAvailability(hotelId: 'h4', checkIn: ci, checkOut: co, guests: 2);
    final room = before.firstWhere((r) => (r.available ?? 0) > 0);

    final booking = await repo.createBooking(
      hotelId: 'h4',
      roomId: room.id,
      checkIn: ci,
      checkOut: co,
      guests: 2,
      guestName: 'Test User',
      email: 'test@example.com',
      phone: '9876543210',
    );
    expect(booking.status, 'pending');
    expect(booking.nights, 2);
    expect(booking.total, closeTo(room.pricePerNight * 2 * 1.12, 1));

    final after = await repo.getAvailability(hotelId: 'h4', checkIn: ci, checkOut: co, guests: 2);
    expect(after.firstWhere((r) => r.id == room.id).available, room.available! - 1);

    expect(
      () => repo.createBooking(
        hotelId: 'h4',
        roomId: room.id,
        checkIn: co,
        checkOut: ci, // reversed
        guests: 2,
        guestName: 'Test User',
        email: 'test@example.com',
        phone: '9876543210',
      ),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 422)),
    );
  });

  test('cancelling twice returns 409', () async {
    final first = (await repo.getBookings()).firstWhere((b) => b.isUpcoming);
    final cancelled = await repo.cancelBooking(first.id);
    expect(cancelled.status, 'cancelled');
    expect(() => repo.cancelBooking(first.id), throwsA(isA<ApiException>().having((e) => e.code, 'code', 409)));
  });
}
