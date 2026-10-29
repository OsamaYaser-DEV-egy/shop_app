import 'package:equatable/equatable.dart';

enum FavoritesStatus {
  /// No customer is signed in.
  signedOut,
  loading,
  success,
  failure,
}

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.signedOut,
    this.ids = const {},
    this.message,
  });

  final FavoritesStatus status;

  /// Ids of the saved products.
  final Set<String> ids;
  final String? message;

  bool isFavorite(String productId) => ids.contains(productId);

  @override
  List<Object?> get props => [status, ids, message];
}
