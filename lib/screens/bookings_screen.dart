import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../providers/bookings_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/view_state.dart';
import '../widgets/common.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BookingsProvider>();
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('My bookings', style: Theme.of(context).textTheme.headlineMedium),
            ),
          ),
          const TabBar(
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.teal,
            dividerColor: AppColors.line,
            tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past'), Tab(text: 'Cancelled')],
          ),
          Expanded(child: _content(context, p)),
        ]),
      ),
    );
  }

  Widget _content(BuildContext context, BookingsProvider p) {
    if (p.state == ViewState.loading || p.state == ViewState.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.state == ViewState.error) {
      return ErrorView(message: p.error ?? 'Please try again.', onRetry: p.load);
    }
    return TabBarView(children: [
      _BookingList(
        items: p.upcoming,
        empty: EmptyView(
          icon: Icons.luggage_outlined,
          title: 'No upcoming trips',
          message: 'Your next booking will show up here.',
          actionLabel: 'Explore hotels',
          onAction: () => context.read<NavProvider>().go(0),
        ),
      ),
      _BookingList(
        items: p.past,
        empty: const EmptyView(icon: Icons.history_rounded, title: 'No past stays', message: 'Completed stays will appear here.'),
      ),
      _BookingList(
        items: p.cancelled,
        empty: const EmptyView(icon: Icons.event_busy_rounded, title: 'Nothing cancelled', message: 'Cancelled bookings will appear here.'),
      ),
    ]);
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> items;
  final Widget empty;
  const _BookingList({required this.items, required this.empty});

  @override
  Widget build(BuildContext context) {
    final p = context.read<BookingsProvider>();
    return RefreshIndicator(
      onRefresh: () => p.load(silent: true),
      child: items.isEmpty
          ? LayoutBuilder(
              builder: (_, c) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: c.maxHeight, child: empty),
              ),
            )
          : ContentWidth(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _BookingCard(booking: items[i]),
              ),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  Future<void> _cancel(BuildContext context) async {
    final p = context.read<BookingsProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text('${booking.hotelName}, ${formatShort(booking.checkIn)} – ${formatShort(booking.checkOut)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep booking')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await p.cancel(booking.id);
    if (!context.mounted) return;
    showSnack(context, err ?? 'Booking ${booking.id} cancelled', error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<BookingsProvider>().cancelling.contains(booking.id);
    final (label, color) = switch (booking.status) {
      'confirmed' => ('Confirmed', AppColors.teal),
      'pending' => ('Pending', AppColors.amber),
      'cancelled' => ('Cancelled', AppColors.danger),
      _ => ('Completed', AppColors.muted),
    };

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
            child: SizedBox(width: 80, height: 80, child: NetImage(booking.hotelImage)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(booking.hotelName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(label, style: TextStyle(color: color == AppColors.amber ? const Color(0xFF9A6200) : color, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${booking.roomName} · ${booking.city}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              Text('${formatShort(booking.checkIn)} – ${formatDate(booking.checkOut)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${booking.nights} nights · ${booking.guests} guests', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ]),
          ),
        ]),
        const Divider(height: 24),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking.id, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              Text(formatMoney(booking.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ]),
          ),
          if (booking.isUpcoming)
            OutlinedButton(
              onPressed: busy ? null : () => _cancel(context),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              child: busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cancel'),
            ),
        ]),
      ]),
    );
  }
}
