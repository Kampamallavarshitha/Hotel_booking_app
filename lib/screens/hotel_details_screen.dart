import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/amenities.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../providers/hotel_details_provider.dart';
import '../providers/view_state.dart';
import '../repositories/hotel_repository.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';

class HotelDetailsScreen extends StatelessWidget {
  final Hotel hotel;
  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => HotelDetailsProvider(c.read<HotelRepository>(), hotel)..load(),
      child: const _DetailsView(),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HotelDetailsProvider>();
    final h = p.hotel;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          backgroundColor: AppColors.ink,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink), onPressed: () => Navigator.pop(context)),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(background: _Gallery(images: h.images)),
        ),
        SliverToBoxAdapter(
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(h.name, style: t.headlineMedium)),
                  const SizedBox(width: 12),
                  RatingBadge(h.rating),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.place_outlined, size: 18, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Expanded(child: Text(h.address, style: const TextStyle(color: AppColors.muted))),
                ]),
                const SizedBox(height: 4),
                Text('${h.reviewCount} reviews', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 20),
                Text('About', style: t.titleLarge),
                const SizedBox(height: 8),
                Text(h.description, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 20),
                Text('Facilities', style: t.titleLarge),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final a in h.amenities)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(amenityIcon(a), size: 18, color: AppColors.teal),
                        const SizedBox(width: 6),
                        Text(a, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 24),
                Text('Rooms', style: t.titleLarge),
                const SizedBox(height: 10),
                _rooms(context, p),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _rooms(BuildContext context, HotelDetailsProvider p) {
    if (p.state == ViewState.error) {
      return ErrorView(message: p.error ?? 'Please try again.', onRetry: p.load, compact: true);
    }
    if (p.state != ViewState.success) {
      return const Column(children: [
        SkeletonBox(height: 170),
        SizedBox(height: 12),
        SkeletonBox(height: 170),
      ]);
    }
    return Column(children: [
      for (final r in p.hotel.rooms)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RoomTile(
            room: r,
            onSelect: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookingScreen(hotel: p.hotel, initialRoomId: r.id)),
            ),
          ),
        ),
    ]);
  }
}

class _Gallery extends StatefulWidget {
  final List<String> images;
  const _Gallery({required this.images});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) => NetImage(widget.images[i]),
      ),
      const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Color(0x00000000), Color(0x66000000)],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 14,
        left: 0,
        right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.images.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: i == _page ? 20 : 6,
              decoration: BoxDecoration(
                color: i == _page ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ]),
      ),
    ]);
  }
}

class _RoomTile extends StatelessWidget {
  final Room room;
  final VoidCallback onSelect;
  const _RoomTile({required this.room, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 96, height: 96, child: NetImage(room.image)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(room.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 4, children: [
                _meta(Icons.bed_outlined, room.bed),
                _meta(Icons.people_outline_rounded, 'Sleeps ${room.capacity}'),
                _meta(Icons.square_foot_rounded, '${room.sizeSqm} m²'),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text(formatMoney(room.pricePerNight), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Text(' /night', style: TextStyle(color: AppColors.muted)),
          const Spacer(),
          FilledButton(onPressed: onSelect, child: const Text('Select room')),
        ]),
      ]),
    );
  }

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}
