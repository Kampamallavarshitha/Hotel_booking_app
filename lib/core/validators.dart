class Validators {
  static String? name(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter your full name';
    if (t.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter your phone number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(t)) return 'Enter a valid 10-digit mobile number';
    return null;
  }
}
