/// Order lifecycle. Values are stored in Firestore by [name].
///
/// Business rules (repeated in `firestore.rules`):
/// - The store moves an order forward one step at a time:
///   pending → confirmed → preparing → shipped → delivered.
/// - The store may cancel an order until it ships.
/// - A customer may cancel their own order while it is still pending.
/// - Cancelling returns the ordered units to stock.
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  preparing('Preparing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  final String label;

  /// The status the store can move this order to, or null when final.
  OrderStatus? get next => switch (this) {
        pending => confirmed,
        confirmed => preparing,
        preparing => shipped,
        shipped => delivered,
        delivered || cancelled => null,
      };

  bool get canBeCancelledByStore =>
      this == pending || this == confirmed || this == preparing;

  bool get canBeCancelledByCustomer => this == pending;

  bool get isFinal => this == delivered || this == cancelled;

  static OrderStatus? fromName(Object? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }
}
