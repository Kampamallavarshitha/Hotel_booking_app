import 'package:flutter/material.dart';

import '../core/amenities.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/hotel.dart';

class FilterSheet extends StatefulWidget {
  final HotelFilters initial;
  final ValueChanged<HotelFilters> onApply;

  const FilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late HotelFilters f = widget.initial;

  static const Map<String, String> _sorts = {
    'recommended': 'Recommended',
    'price_asc': 'Price: low to high',
    'price_desc': 'Price: high to low',
    'rating': 'Top rated',
  };

  // Integer keys avoid decimal keys in the map.
  // 45 represents a rating of 4.5.
  static const Map<int, String> _ratings = {
    0: 'Any',
    3: '3+',
    4: '4+',
    45: '4.5+',
  };

  double _ratingValue(int key) {
    return key == 45 ? 4.5 : key.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Filters', style: t.titleLarge),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    f = const HotelFilters();
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Price range
                  Text('Price per night', style: t.titleMedium),

                  RangeSlider(
                    values: RangeValues(f.minPrice, f.maxPrice),
                    min: 0,
                    max: HotelFilters.priceCeiling,
                    divisions: 40,
                    labels: RangeLabels(
                      formatMoney(f.minPrice),
                      formatMoney(f.maxPrice),
                    ),
                    onChanged: (v) {
                      setState(() {
                        f = f.copyWith(
                          minPrice: v.start,
                          maxPrice: v.end,
                        );
                      });
                    },
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatMoney(f.minPrice),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      Text(
                        f.maxPrice >= HotelFilters.priceCeiling
                            ? '${formatMoney(f.maxPrice)}+'
                            : formatMoney(f.maxPrice),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Minimum rating
                  Text('Minimum rating', style: t.titleMedium),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      for (final e in _ratings.entries)
                        ChoiceChip(
                          label: Text(e.value),
                          selected: f.minRating == _ratingValue(e.key),
                          onSelected: (_) {
                            setState(() {
                              f = f.copyWith(
                                minRating: _ratingValue(e.key),
                              );
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Amenities
                  Text('Amenities', style: t.titleMedium),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final a in kAmenities)
                        FilterChip(
                          avatar: Icon(amenityIcon(a), size: 16),
                          label: Text(a),
                          selected: f.amenities.contains(a),
                          onSelected: (on) {
                            final next = {...f.amenities};

                            if (on) {
                              next.add(a);
                            } else {
                              next.remove(a);
                            }

                            setState(() {
                              f = f.copyWith(amenities: next);
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sorting
                  Text('Sort by', style: t.titleMedium),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final e in _sorts.entries)
                        ChoiceChip(
                          label: Text(e.value),
                          selected: f.sort == e.key,
                          onSelected: (_) {
                            setState(() {
                              f = f.copyWith(sort: e.key);
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Apply filters
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(f);
                Navigator.pop(context);
              },
              child: const Text('Show stays'),
            ),
          ),
        ],
      ),
    );
  }
}
