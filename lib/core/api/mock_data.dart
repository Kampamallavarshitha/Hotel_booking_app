// Seed data for the mock backend. Images are Unsplash URLs (needs internet);
// the UI shows a placeholder if one fails to load.

String _img(String id) => 'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=1000&q=70';

Map<String, dynamic> _room(String id, String name, String desc, int price, int cap, String bed, int size, int total, String img) => {
      'id': id,
      'name': name,
      'description': desc,
      'pricePerNight': price,
      'capacity': cap,
      'bed': bed,
      'sizeSqm': size,
      'totalRooms': total,
      'image': _img(img),
    };

Map<String, dynamic> _hotel({
  required String id,
  required String name,
  required String city,
  required String state,
  required String address,
  required String description,
  required List<String> images,
  required double rating,
  required int reviews,
  required List<String> amenities,
  required List<Map<String, dynamic>> rooms,
}) =>
    {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'address': address,
      'description': description,
      'images': images.map(_img).toList(),
      'rating': rating,
      'reviewCount': reviews,
      // "From" price = cheapest room.
      'pricePerNight': rooms.map((r) => r['pricePerNight'] as int).reduce((a, b) => a < b ? a : b),
      'amenities': amenities,
      'rooms': rooms,
    };

final List<Map<String, dynamic>> seedHotels = [
  _hotel(
    id: 'h1',
    name: 'Azure Bay Resort',
    city: 'Calangute',
    state: 'Goa',
    address: 'Candolim Beach Road, Calangute, Goa 403516',
    description:
        'A beachfront resort a short walk from the shoreline, with a palm-lined pool deck, an all-day seafood restaurant and rooms that open to the sea breeze. Ideal for relaxed weekends and family holidays.',
    images: ['1566073771259-6a8506099945', '1520250497591-112f2f40a3f4', '1582719508461-905c673771fd'],
    rating: 4.6,
    reviews: 1284,
    amenities: ['Wi-Fi', 'Pool', 'Spa', 'Parking', 'Restaurant', 'Breakfast', 'Beach access'],
    rooms: [
      _room('h1r1', 'Garden View Room', 'Quiet room overlooking the tropical garden.', 6200, 2, '1 Queen bed', 28, 6, '1590490360182-c33d57733427'),
      _room('h1r2', 'Sea View Deluxe', 'Private balcony with sunset views over the Arabian Sea.', 8900, 3, '1 King bed + sofa', 36, 4, '1618773928121-c32242e63f39'),
      _room('h1r3', 'Family Suite', 'Two connected rooms with a lounge and kids’ corner.', 14500, 5, '1 King + 2 Singles', 62, 2, '1578683010236-d716f9a3f461'),
    ],
  ),
  _hotel(
    id: 'h2',
    name: 'The Amber Haveli',
    city: 'Jaipur',
    state: 'Rajasthan',
    address: 'Amer Road, Jaipur, Rajasthan 302002',
    description:
        'A restored 19th-century haveli with a courtyard fountain, hand-painted ceilings and rooftop dining that faces Nahargarh Fort. Heritage charm with modern comfort.',
    images: ['1564501049412-61c2a3083791', '1551882547-ff40c63fe5fa', '1542314831-068cd1dbfeeb'],
    rating: 4.8,
    reviews: 932,
    amenities: ['Wi-Fi', 'Spa', 'Restaurant', 'Breakfast', 'Parking'],
    rooms: [
      _room('h2r1', 'Heritage Room', 'Arched windows and hand-block printed linens.', 5400, 2, '1 Queen bed', 26, 5, '1590490360182-c33d57733427'),
      _room('h2r2', 'Maharani Suite', 'Four-poster bed, private sit-out and a clawfoot tub.', 12800, 3, '1 King bed', 48, 2, '1618773928121-c32242e63f39'),
    ],
  ),
  _hotel(
    id: 'h3',
    name: 'Backwater Bliss',
    city: 'Alleppey',
    state: 'Kerala',
    address: 'Punnamada Lake Road, Alappuzha, Kerala 688001',
    description:
        'Cottages on stilts over calm backwaters. Start the day with a canoe ride, end it with Kerala-style dinner by the water.',
    images: ['1520250497591-112f2f40a3f4', '1566073771259-6a8506099945', '1596394516093-501ba68a0ba6'],
    rating: 4.5,
    reviews: 611,
    amenities: ['Wi-Fi', 'Pool', 'Spa', 'Restaurant', 'Breakfast'],
    rooms: [
      _room('h3r1', 'Lake Cottage', 'Wooden cottage with a deck over the water.', 7200, 2, '1 King bed', 30, 5, '1590490360182-c33d57733427'),
      _room('h3r2', 'Premium Villa', 'Private plunge pool and open-air shower.', 16500, 4, '1 King + 1 Double', 58, 2, '1578683010236-d716f9a3f461'),
    ],
  ),
  _hotel(
    id: 'h4',
    name: 'Bay of Bengal Inn',
    city: 'Visakhapatnam',
    state: 'Andhra Pradesh',
    address: 'Beach Road, Visakhapatnam, Andhra Pradesh 530003',
    description:
        'A business-friendly hotel on Beach Road with sea-facing rooms, a rooftop café and quick access to Kailasagiri and RK Beach.',
    images: ['1551882547-ff40c63fe5fa', '1542314831-068cd1dbfeeb', '1582719508461-905c673771fd'],
    rating: 4.2,
    reviews: 745,
    amenities: ['Wi-Fi', 'Gym', 'Restaurant', 'Breakfast', 'Parking'],
    rooms: [
      _room('h4r1', 'Standard Room', 'Compact, quiet and well-lit.', 3200, 2, '1 Queen bed', 22, 8, '1590490360182-c33d57733427'),
      _room('h4r2', 'Sea Facing Deluxe', 'Floor-to-ceiling windows overlooking the bay.', 4800, 3, '1 King bed + sofa', 30, 4, '1618773928121-c32242e63f39'),
    ],
  ),
  _hotel(
    id: 'h5',
    name: 'Lakeside Palace Retreat',
    city: 'Udaipur',
    state: 'Rajasthan',
    address: 'Lake Pichola Road, Udaipur, Rajasthan 313001',
    description:
        'Marble terraces, lake-facing suites and evening boat rides to the City Palace. A romantic stay in the City of Lakes.',
    images: ['1542314831-068cd1dbfeeb', '1564501049412-61c2a3083791', '1551882547-ff40c63fe5fa'],
    rating: 4.9,
    reviews: 1520,
    amenities: ['Wi-Fi', 'Pool', 'Spa', 'Restaurant', 'Breakfast', 'Gym', 'Parking'],
    rooms: [
      _room('h5r1', 'Lake View Room', 'Window seat framing Lake Pichola.', 11200, 2, '1 King bed', 32, 4, '1590490360182-c33d57733427'),
      _room('h5r2', 'Royal Suite', 'Private terrace, butler service and a living room.', 19500, 3, '1 King bed', 70, 2, '1578683010236-d716f9a3f461'),
    ],
  ),
  _hotel(
    id: 'h6',
    name: 'Pine Ridge Lodge',
    city: 'Manali',
    state: 'Himachal Pradesh',
    address: 'Old Manali Road, Manali, Himachal Pradesh 175131',
    description:
        'A timber lodge among deodar trees with a log-fire lounge and mountain views from every room. Great base for treks and snow days.',
    images: ['1596394516093-501ba68a0ba6', '1582719508461-905c673771fd', '1564501049412-61c2a3083791'],
    rating: 4.3,
    reviews: 458,
    amenities: ['Wi-Fi', 'Restaurant', 'Breakfast', 'Parking'],
    rooms: [
      _room('h6r1', 'Cozy Cabin Room', 'Wood-panelled room with a heater and valley view.', 4200, 2, '1 Queen bed', 24, 6, '1590490360182-c33d57733427'),
      _room('h6r2', 'Family Loft', 'Split-level loft that sleeps the whole family.', 7800, 5, '1 King + 2 Singles', 45, 3, '1578683010236-d716f9a3f461'),
    ],
  ),
  _hotel(
    id: 'h7',
    name: 'Marine Drive Grand',
    city: 'Mumbai',
    state: 'Maharashtra',
    address: 'Netaji Subhash Road, Marine Drive, Mumbai 400020',
    description:
        'City hotel facing the Queen’s Necklace, close to Churchgate and South Mumbai’s cafés. Rooms are quiet, bright and built for short trips.',
    images: ['1551882547-ff40c63fe5fa', '1566073771259-6a8506099945', '1542314831-068cd1dbfeeb'],
    rating: 4.4,
    reviews: 2103,
    amenities: ['Wi-Fi', 'Gym', 'Restaurant', 'Breakfast', 'Spa'],
    rooms: [
      _room('h7r1', 'City Room', 'Efficient layout with a work desk.', 9400, 2, '1 Queen bed', 24, 7, '1590490360182-c33d57733427'),
      _room('h7r2', 'Sea View Executive', 'Corner room with lounge access.', 13800, 3, '1 King bed', 38, 3, '1618773928121-c32242e63f39'),
    ],
  ),
  _hotel(
    id: 'h8',
    name: 'Nizam’s Courtyard',
    city: 'Hyderabad',
    state: 'Telangana',
    address: 'Banjara Hills Road No. 12, Hyderabad, Telangana 500034',
    description:
        'Boutique hotel with a courtyard garden and an in-house Hyderabadi kitchen. Five minutes from the business district.',
    images: ['1582719508461-905c673771fd', '1551882547-ff40c63fe5fa', '1564501049412-61c2a3083791'],
    rating: 4.1,
    reviews: 389,
    amenities: ['Wi-Fi', 'Pool', 'Gym', 'Restaurant', 'Parking', 'Breakfast'],
    rooms: [
      _room('h8r1', 'Classic Room', 'Calm interiors with a garden view.', 3800, 2, '1 Queen bed', 24, 6, '1590490360182-c33d57733427'),
      _room('h8r2', 'Courtyard Suite', 'Opens directly to the courtyard and pool.', 6900, 4, '1 King + 1 Sofa bed', 44, 3, '1578683010236-d716f9a3f461'),
    ],
  ),
];
