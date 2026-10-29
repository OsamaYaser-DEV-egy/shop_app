enum UserRole {
  customer,
  admin;

  /// Returns null for missing or unknown values so callers never grant
  /// privileges by accident.
  static UserRole? tryParse(Object? value) {
    if (value is! String) return null;
    switch (value) {
      case 'customer':
        return UserRole.customer;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }
}
