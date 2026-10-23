import 'package:flutter/material.dart';

import '../core/amenities.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/hotel.dart';
import 'common.dart';

/// Fixed-height card; used inside a grid whose column count adapts to width.
class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onTap;
  const HotelCard({super.key, required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              NetImage(hotel.cover),
              Positioned(top: 12, left: 12, child: RatingBadge(hotel.rating, onImage: true)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hotel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(hotel.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                for (final a in hotel.amenities.take(4))
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(amenityIcon(a), size: 18, color: AppColors.muted),
                  ),
                const Spacer(),
                Text(formatMoney(hotel.pricePerNight), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink)),
                const Text(' /night', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class HotelCardSkeleton extends StatelessWidget {
  const HotelCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.all(10),
        child: const Column(children: [
          Expanded(child: SkeletonBox(radius: 14)),
          SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: SkeletonBox(height: 16, width: 160)),
          SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: SkeletonBox(height: 12, width: 110)),
          SizedBox(height: 14),
        ]),
      );
}
