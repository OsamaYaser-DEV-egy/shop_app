import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/products/domain/entities/product_draft.dart';
import 'package:shop_app/features/products/domain/repositories/product_repository.dart';
import 'package:shop_app/features/products/domain/usecases/create_product.dart';
import 'package:shop_app/features/products/domain/usecases/delete_product.dart';
import 'package:shop_app/features/products/domain/usecases/update_product.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

const _validDraft = ProductDraft(
  name: 'Headphones',
  description: 'Wireless',
  price: 49.99,
  imageUrl: 'https://example.com/a.png',
  category: 'Audio',
  stock: 10,
  isAvailable: true,
);

void main() {
  late _MockProductRepository repository;

  setUpAll(() => registerFallbackValue(_validDraft));

  setUp(() => repository = _MockProductRepository());

  group('ProductDraft.validationError', () {
    test('accepts a valid draft and an empty image URL', () {
      expect(_validDraft.validationError, isNull);
      const noImage = ProductDraft(
        name: 'Cable',
        description: '',
        price: 5,
        imageUrl: '',
        category: 'Misc',
        stock: 0,
        isAvailable: false,
      );
      expect(noImage.validationError, isNull);
    });

    test('rejects bad values', () {
      ProductDraft draft({
        String name = 'Cable',
        double price = 5,
        int stock = 1,
        String category = 'Misc',
        String imageUrl = '',
      }) =>
          ProductDraft(
            name: name,
            description: '',
            price: price,
            imageUrl: imageUrl,
            category: category,
            stock: stock,
            isAvailable: true,
          );

      expect(draft(name: ' ').validationError, isNotNull);
      expect(draft(price: 0).validationError, isNotNull);
      expect(draft(price: -3).validationError, isNotNull);
      expect(draft(price: double.nan).validationError, isNotNull);
      expect(draft(stock: -1).validationError, isNotNull);
      expect(draft(category: '').validationError, isNotNull);
      expect(draft(imageUrl: 'not a url').validationError, isNotNull);
      expect(draft(imageUrl: 'ftp://host/file').validationError, isNotNull);
    });
  });

  group('CreateProduct', () {
    test('saves a valid draft', () async {
      when(() => repository.createProduct(any())).thenAnswer((_) async {});
      await CreateProduct(repository)(_validDraft);
      verify(() => repository.createProduct(_validDraft)).called(1);
    });

    test('rejects an invalid draft without calling the repository', () async {
      const bad = ProductDraft(
        name: 'X',
        description: '',
        price: 5,
        imageUrl: '',
        category: 'Misc',
        stock: 1,
        isAvailable: true,
      );
      await expectLater(CreateProduct(repository)(bad), throwsA(isA<Failure>()));
      verifyNever(() => repository.createProduct(any()));
    });
  });

  group('UpdateProduct', () {
    test('updates with a valid draft', () async {
      when(() => repository.updateProduct(any(), any())).thenAnswer((_) async {});
      await UpdateProduct(repository)('p1', _validDraft);
      verify(() => repository.updateProduct('p1', _validDraft)).called(1);
    });

    test('rejects an empty id', () async {
      await expectLater(
        UpdateProduct(repository)('', _validDraft),
        throwsA(isA<Failure>()),
      );
      verifyNever(() => repository.updateProduct(any(), any()));
    });
  });

  group('DeleteProduct', () {
    test('deletes by id', () async {
      when(() => repository.deleteProduct(any())).thenAnswer((_) async {});
      await DeleteProduct(repository)('p1');
      verify(() => repository.deleteProduct('p1')).called(1);
    });

    test('rejects an empty id', () async {
      await expectLater(DeleteProduct(repository)(''), throwsA(isA<Failure>()));
      verifyNever(() => repository.deleteProduct(any()));
    });
  });
}
