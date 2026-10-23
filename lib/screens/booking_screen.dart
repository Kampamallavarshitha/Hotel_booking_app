import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../providers/bookings_provider.dart';
import '../providers/nav_provider.dart';
import '../repositories/hotel_repository.dart';
import '../widgets/common.dart';
import '../providers/view_state.dart';

class BookingScreen extends StatefulWidget {
  final Hotel hotel;
  final String initialRoomId;

  const BookingScreen({
    super.key,
    required this.hotel,
    required this.initialRoomId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  late Room _room;
  late DateTime _checkIn;
  late DateTime _checkOut;

  int _guests = 1;
  bool _submitting = false;

  // Estimated tax for the price preview. The server's returned
  // booking total is authoritative after submission.
  static const double _estimatedTaxRate = 0.12;

  int get _nights => _checkOut.difference(_checkIn).inDays;

  double get _subtotal => _room.pricePerNight * _nights;

  double get _estimatedTax => _subtotal * _estimatedTaxRate;

  double get _estimatedTotal => _subtotal + _estimatedTax;

  @override
  void initState() {
    super.initState();

    _room = widget.hotel.rooms.firstWhere(
      (r) => r.id == widget.initialRoomId,
      orElse: () => widget.hotel.rooms.first,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _checkIn = today.add(const Duration(days: 1));
    _checkOut = today.add(const Duration(days: 2));
    _guests = _room.capacity < 2 ? 1 : 2;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final firstDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: isCheckIn ? 'Select check-in date' : 'Select check-out date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.teal,
              ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = DateTime(picked.year, picked.month, picked.day);

        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else if (picked.isAfter(_checkIn)) {
        _checkOut = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  Future<void> _submitBooking() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (!_checkOut.isAfter(_checkIn)) {
      showSnack(context, 'Check-out must be after check-in.', error: true);
      return;
    }

    if (_guests > _room.capacity) {
      showSnack(
        context,
        'This room accommodates up to ${_room.capacity} guests.',
        error: true,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final booking = await context.read<HotelRepository>().createBooking(
            hotelId: widget.hotel.id,
            roomId: _room.id,
            checkIn: _checkIn,
            checkOut: _checkOut,
            guests: _guests,
            guestName: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            notes: _notes.text.trim(),
          );

      if (!mounted) return;

      context.read<BookingsProvider>().addBooking(booking);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.teal,
            size: 52,
          ),
          title: const Text('Request submitted!'),
          content: Text(
            '${widget.hotel.name}\n'
            '${formatShort(booking.checkIn)} – ${formatShort(booking.checkOut)}\n\n'
            'Booking ID: ${booking.id}\n'
            'Status: ${booking.status}\n'
            'Total: ${formatMoney(booking.total)}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Return to the app shell and open the bookings tab.
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<NavProvider>().go(1);
    } catch (e) {
      if (!mounted) return;

      showSnack(
        context,
        'Could not submit booking: ${errorMessage(e)}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your booking'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hotel and selected room.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: NetImage(_room.image),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotel.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _room.name,
                            style: const TextStyle(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${formatMoney(_room.pricePerNight)} / night',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            'Up to ${_room.capacity} guests',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Stay dates'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _dateCard(
                      label: 'CHECK-IN',
                      date: _checkIn,
                      onTap: () => _pickDate(isCheckIn: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateCard(
                      label: 'CHECK-OUT',
                      date: _checkOut,
                      onTap: () => _pickDate(isCheckIn: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                '$_nights ${_nights == 1 ? 'night' : 'nights'} selected',
                style: const TextStyle(color: AppColors.muted),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Guests'),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline_rounded),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Number of guests')),
                    IconButton(
                      onPressed:
                          _guests > 1 ? () => setState(() => _guests--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_guests',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: _guests < _room.capacity
                          ? () => setState(() => _guests++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Guest details'),
              const SizedBox(height: 12),

              _field(
                controller: _name,
                label: 'Full name',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 12),

              _field(
                controller: _email,
                label: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter your email address';
                  }
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _field(
                controller: _phone,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null ||
                      v.trim().replaceAll(RegExp(r'\D'), '').length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _field(
                controller: _notes,
                label: 'Special requests (optional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
                required: false,
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Price summary'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _priceRow(
                      '${formatMoney(_room.pricePerNight)} × $_nights nights',
                      formatMoney(_subtotal),
                    ),
                    const SizedBox(height: 10),
                    _priceRow(
                      'Estimated taxes (12%)',
                      formatMoney(_estimatedTax),
                    ),
                    const Divider(height: 24),
                    _priceRow(
                      'Estimated total',
                      formatMoney(_estimatedTotal),
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Final taxes and total are confirmed by the booking service.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submitBooking,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting
                        ? 'Submitting request...'
                        : 'Send Booking Request',
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'Your request will be submitted to the booking service. '
                'The returned status will be shown after submission.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _dateCard({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.teal,
                  size: 19,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatShort(date),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Tap to change',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required ? validator : null,
      textCapitalization: label == 'Full name'
          ? TextCapitalization.words
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _priceRow(String label, String amount, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
