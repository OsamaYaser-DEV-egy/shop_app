import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_draft.dart';
import '../../../products/presentation/cubit/product_management_cubit.dart';
import '../../../products/presentation/cubit/product_management_state.dart';
import '../../../products/presentation/widgets/product_image.dart';

/// Create/edit form. Pass [productId] and [initial] to edit.
class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.productId, this.initial});

  final String? productId;
  final Product? initial;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late final TextEditingController _description;
  late bool _isAvailable;
  late bool _isFeatured;

  /// The preview refreshes when the URL field is submitted, not on every key,
  /// to avoid firing a network request per keystroke.
  late String _previewUrl;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(2));
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _isAvailable = p?.isAvailable ?? true;
    _isFeatured = p?.isFeatured ?? false;
    _previewUrl = p?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    final url = _imageUrl.text.trim();
    if (Validators.optionalImageUrl(url) == null) {
      setState(() => _previewUrl = url);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final price = double.parse(_price.text.trim().replaceAll(',', '.'));
    final draft = ProductDraft(
      name: _name.text.trim(),
      description: _description.text.trim(),
      price: (price * 100).round() / 100,
      imageUrl: _imageUrl.text.trim(),
      category: _category.text.trim(),
      stock: int.parse(_stock.text.trim()),
      isAvailable: _isAvailable,
      isFeatured: _isFeatured,
    );
    context.read<ProductManagementCubit>().save(
          id: widget.productId,
          draft: draft,
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ProductImage(url: _previewUrl),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _name,
              label: 'Product name',
              icon: Icons.label_outline,
              textInputAction: TextInputAction.next,
              validator: Validators.productName,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _category,
              label: 'Category (e.g. Electronics)',
              icon: Icons.category_outlined,
              textInputAction: TextInputAction.next,
              validator: Validators.category,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _price,
                    label: 'Price',
                    icon: Icons.sell_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: Validators.price,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _stock,
                    label: 'Stock',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.stock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _imageUrl,
              label: 'Image URL (optional)',
              icon: Icons.link,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              validator: Validators.optionalImageUrl,
              onSubmitted: (_) => _refreshPreview(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _refreshPreview,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Preview image'),
              ),
            ),
            const SizedBox(height: 4),
            AppTextField(
              controller: _description,
              label: 'Description',
              icon: Icons.notes,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              validator: Validators.description,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for purchase'),
              subtitle: const Text('Turn off to hide the buy option.'),
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured on home screen'),
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ProductManagementCubit, ProductManagementState>(
              buildWhen: (p, c) => p.isBusy != c.isBusy,
              builder: (context, state) => LoadingButton(
                label: _isEdit ? 'Save changes' : 'Create product',
                isLoading: state.isBusy,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
