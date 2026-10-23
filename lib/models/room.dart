class Room {
  final String id, name, description, bed, image;
  final double pricePerNight;
  final int capacity, sizeSqm, totalRooms;

  /// Only present on responses from `/hotels/{id}/availability`.
  final int? available;

  const Room({
    required this.id,
    required this.name,
    required this.description,
    required this.bed,
    required this.image,
    required this.pricePerNight,
    required this.capacity,
    required this.sizeSqm,
    required this.totalRooms,
    this.available,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        bed: j['bed'],
        image: j['image'],
        pricePerNight: (j['pricePerNight'] as num).toDouble(),
        capacity: j['capacity'],
        sizeSqm: j['sizeSqm'],
        totalRooms: j['totalRooms'],
        available: j['available'],
      );
}
