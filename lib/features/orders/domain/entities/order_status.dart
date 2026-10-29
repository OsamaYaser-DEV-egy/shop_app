/// Order lifecycle. Values are stored in Firestore by [name].
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  preparing('Preparing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  final String label;

  static OrderStatus? fromName(Object? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }
}
