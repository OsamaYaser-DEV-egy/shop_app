import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_messenger.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

/// Heart toggle for one product.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.productId,
    this.onImage = false,
  });

  final String productId;

  /// Draws a small translucent circle behind the icon so it stays visible
  /// on top of product pictures.
  final bool onImage;

  Future<void> _toggle(BuildContext context) async {
    final failure = await context.read<FavoritesCubit>().toggle(productId);
    if (failure != null) AppMessenger.showError(failure.message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FavoritesCubit, FavoritesState, bool>(
      selector: (state) => state.isFavorite(productId),
      builder: (context, isFavorite) {
        final button = IconButton(
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          visualDensity: onImage ? VisualDensity.compact : null,
          iconSize: onImage ? 20 : null,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.error : null,
          ),
          onPressed: () => _toggle(context),
        );
        if (!onImage) return button;
        return Material(
          color: AppColors.background.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          child: button,
        );
      },
    );
  }
}
