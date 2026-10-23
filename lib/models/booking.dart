import '../core/format.dart';

class Booking {
  final String id, hotelId, hotelName, hotelImage, city, roomName, status;
  final String guestName, email, phone, notes;
  final DateTime checkIn, checkOut, createdAt;
  final int guests, nights;
  final double subtotal, taxes, total;

  const Booking({
    required this.id,
    required this.hotelId,
    required this.hotelName,
    required this.hotelImage,
    required this.city,
    required this.roomName,
    required this.status,
    required this.guestName,
    required this.email,
    required this.phone,
    required this.notes,
    required this.checkIn,
    required this.checkOut,
    required this.createdAt,
    required this.guests,
    required this.nights,
    required this.subtotal,
    required this.taxes,
    required this.total,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'],
        hotelId: j['hotelId'],
        hotelName: j['hotelName'],
        hotelImage: j['hotelImage'],
        city: j['city'],
        roomName: j['roomName'],
        status: j['status'],
        guestName: j['guestName'],
        email: j['email'],
        phone: j['phone'],
        notes: j['notes'] ?? '',
        checkIn: DateTime.parse(j['checkIn']),
        checkOut: DateTime.parse(j['checkOut']),
        createdAt: DateTime.parse(j['createdAt']),
        guests: j['guests'],
        nights: j['nights'],
        subtotal: (j['subtotal'] as num).toDouble(),
        taxes: (j['taxes'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
      );

  bool get isActive => status == 'pending' || status == 'confirmed';
  bool get isUpcoming => isActive && !checkOut.isBefore(today());
  bool get isCancelled => status == 'cancelled';
  bool get isPast => !isCancelled && !isUpcoming;
}

class UserProfile {
  final String name, email, phone;
  const UserProfile({required this.name, required this.email, required this.phone});

  factory UserProfile.fromJson(Map<String, dynamic> j) =>
      UserProfile(name: j['name'], email: j['email'], phone: j['phone']);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }
}
