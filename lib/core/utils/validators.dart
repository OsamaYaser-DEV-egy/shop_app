/// Client-side form validators. Server-side rules repeat the important checks.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phone = RegExp(r'^\+?[0-9\s\-]{7,20}$');

  static const int passwordMinLength = 8;
  static const int nameMaxLength = 80;

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name.';
    if (v.length < 2) return 'Name is too short.';
    if (v.length > nameMaxLength) return 'Name is too long.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email.';
    if (!_email.hasMatch(v)) return 'Please enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password.';
    if (v.length < passwordMinLength) {
      return 'Use at least $passwordMinLength characters.';
    }
    return null;
  }

  /// Login only checks that something was typed; the server decides validity.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? phone(String? value, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Please enter a phone number.' : null;
    if (!_phone.hasMatch(v)) return 'Please enter a valid phone number.';
    return null;
  }

  static String? address(String? value, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Please enter a delivery address.' : null;
    if (v.length < 8) return 'Please enter a more complete address.';
    if (v.length > 300) return 'Address is too long.';
    return null;
  }

  // ---- Product form ----

  static String? productName(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Enter a product name (2+ characters).';
    if (v.length > 120) return 'Name is too long (120 max).';
    return null;
  }

  static String? category(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a category.';
    if (v.length > 40) return 'Category is too long (40 max).';
    return null;
  }

  static String? description(String? value) {
    if ((value?.length ?? 0) > 2000) return 'Description is too long (2000 max).';
    return null;
  }

  static String? price(String? value) {
    final v = (value ?? '').trim().replaceAll(',', '.');
    if (v.isEmpty) return 'Enter a price.';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Enter a valid number.';
    if (parsed <= 0) return 'Price must be greater than 0.';
    if (parsed > 1000000) return 'Price is too high.';
    return null;
  }

  static String? stock(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter the stock quantity.';
    final parsed = int.tryParse(v);
    if (parsed == null) return 'Enter a whole number.';
    if (parsed < 0) return 'Stock cannot be negative.';
    if (parsed > 100000) return 'Stock is too high.';
    return null;
  }

  /// Empty is allowed: the app shows a fallback image.
  static String? optionalImageUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    final ok = uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return ok ? null : 'Enter a valid http(s) image URL.';
  }
}
