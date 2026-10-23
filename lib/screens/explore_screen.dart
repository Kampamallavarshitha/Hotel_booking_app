import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/hotel_list_provider.dart';
import '../providers/view_state.dart';
import '../widgets/common.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/hotel_card.dart';
import 'hotel_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const SliverGridDelegateWithMaxCrossAxisExtent _grid =
      SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 460,
    mainAxisExtent: 340,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  );

  void _openFilters(HotelListProvider p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.bg,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => FilterSheet(
        initial: p.filters,
        onApply: p.apply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HotelListProvider>();
    final filterCount = p.filters.activeCount;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: p.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find your next stay',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hotels across India, from beaches to hill stations',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: p.setQuery,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search city, state or hotel',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        _search.clear();
                                        p.setQuery('');
                                        setState(() {});
                                      },
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Badge(
                          isLabelVisible: filterCount > 0,
                          label: Text('$filterCount'),
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              minimumSize: const Size(52, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            tooltip: 'Filters',
                            onPressed: () => _openFilters(p),
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (p.state == ViewState.success)
                      Text(
                        '${p.hotels.length} '
                        '${p.hotels.length == 1 ? 'stay' : 'stays'} found',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ..._body(p),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(HotelListProvider p) {
    switch (p.state) {
      case ViewState.idle:
      case ViewState.loading:
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverGrid(
              gridDelegate: _grid,
              delegate: SliverChildBuilderDelegate(
                (context, index) => const HotelCardSkeleton(),
                childCount: 4,
              ),
            ),
          ),
        ];

      case ViewState.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              message: p.error ?? 'Please try again.',
              onRetry: p.load,
            ),
          ),
        ];

      case ViewState.success:
        if (p.hotels.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.travel_explore_rounded,
                title: 'No stays match',
                message: 'Try a different place or loosen your filters.',
                actionLabel: 'Clear filters',
                onAction: () {
                  _search.clear();
                  p.setQuery('');
                  p.clearFilters();
                  setState(() {});
                },
              ),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverGrid(
              gridDelegate: _grid,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final hotel = p.hotels[index];

                  return HotelCard(
                    hotel: hotel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotelDetailsScreen(
                            hotel: hotel,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: p.hotels.length,
              ),
            ),
          ),
        ];
    }
  }
}
