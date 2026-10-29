import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/domain/usecases/send_password_reset.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/watch_auth_uid.dart';
import '../../features/auth/presentation/cubit/auth_form_cubit.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/cart/data/datasources/cart_remote_data_source.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/clear_cart.dart';
import '../../features/cart/domain/usecases/remove_from_cart.dart';
import '../../features/cart/domain/usecases/set_cart_quantity.dart';
import '../../features/cart/domain/usecases/watch_cart.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/favorites/data/datasources/favorites_remote_data_source.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/set_favorite.dart';
import '../../features/favorites/domain/usecases/watch_favorites.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/orders/data/datasources/order_remote_data_source.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/usecases/place_order.dart';
import '../../features/orders/domain/usecases/watch_my_orders.dart';
import '../../features/orders/domain/usecases/watch_order.dart';
import '../../features/orders/presentation/cubit/checkout_cubit.dart';
import '../../features/orders/presentation/cubit/my_orders_cubit.dart';
import '../../features/orders/presentation/cubit/order_details_cubit.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/create_product.dart';
import '../../features/products/domain/usecases/delete_product.dart';
import '../../features/products/domain/usecases/update_product.dart';
import '../../features/products/domain/usecases/watch_product.dart';
import '../../features/products/domain/usecases/watch_products.dart';
import '../../features/products/presentation/cubit/product_details_cubit.dart';
import '../../features/products/presentation/cubit/product_list_cubit.dart';
import '../../features/products/presentation/cubit/product_management_cubit.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/domain/usecases/watch_profile.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../routing/app_router.dart';

final GetIt sl = GetIt.instance;

/// Registers all dependencies in one place.
/// Each stage appends its own `_register<Feature>()` call below.
Future<void> configureDependencies() async {
  _registerExternal();
  _registerProfile();
  _registerAuth();
  _registerProducts();
  _registerCart();
  _registerFavorites();
  _registerOrders();
  _registerRouter();
}

void _registerExternal() {
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseFunctions>(() => FirebaseFunctions.instance);
  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
}

void _registerProfile() {
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileRemoteDataSource>()),
  );
  sl.registerLazySingleton<WatchProfile>(
    () => WatchProfile(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<UpdateProfile>(
    () => UpdateProfile(sl<ProfileRepository>()),
  );
  // New instance per profile page; closed automatically by BlocProvider.
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(updateProfile: sl<UpdateProfile>()),
  );
}

void _registerAuth() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authDataSource: sl<AuthRemoteDataSource>(),
      profileDataSource: sl<ProfileRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<WatchAuthUid>(
    () => WatchAuthUid(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignIn>(() => SignIn(sl<AuthRepository>()));
  sl.registerLazySingleton<Register>(() => Register(sl<AuthRepository>()));
  sl.registerLazySingleton<SignOut>(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton<SendPasswordReset>(
    () => SendPasswordReset(sl<AuthRepository>()),
  );

  // App-lifetime cubits: live as long as the app, so they are never closed.
  sl.registerLazySingleton<SessionCubit>(
    () => SessionCubit(
      watchAuthUid: sl<WatchAuthUid>(),
      watchProfile: sl<WatchProfile>(),
      signOut: sl<SignOut>(),
    ),
  );
  sl.registerLazySingleton<AuthFormCubit>(
    () => AuthFormCubit(
      signIn: sl<SignIn>(),
      register: sl<Register>(),
      sendPasswordReset: sl<SendPasswordReset>(),
    ),
  );
}

void _registerProducts() {
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl<ProductRemoteDataSource>()),
  );
  sl.registerLazySingleton<WatchProducts>(
    () => WatchProducts(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<WatchProduct>(
    () => WatchProduct(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<CreateProduct>(
    () => CreateProduct(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<UpdateProduct>(
    () => UpdateProduct(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<DeleteProduct>(
    () => DeleteProduct(sl<ProductRepository>()),
  );

  // Page-scoped cubits: a new instance per page, closed by BlocProvider.
  sl.registerFactory<ProductListCubit>(
    () => ProductListCubit(watchProducts: sl<WatchProducts>()),
  );
  sl.registerFactoryParam<ProductDetailsCubit, String, void>(
    (productId, _) => ProductDetailsCubit(
      watchProduct: sl<WatchProduct>(),
      productId: productId,
    ),
  );
  sl.registerFactory<ProductManagementCubit>(
    () => ProductManagementCubit(
      createProduct: sl<CreateProduct>(),
      updateProduct: sl<UpdateProduct>(),
      deleteProduct: sl<DeleteProduct>(),
    ),
  );
}

void _registerCart() {
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(sl<CartRemoteDataSource>()),
  );
  sl.registerLazySingleton<WatchCart>(() => WatchCart(sl<CartRepository>()));
  sl.registerLazySingleton<SetCartQuantity>(
    () => SetCartQuantity(sl<CartRepository>()),
  );
  sl.registerLazySingleton<RemoveFromCart>(
    () => RemoveFromCart(sl<CartRepository>()),
  );
  sl.registerLazySingleton<ClearCart>(() => ClearCart(sl<CartRepository>()));

  // App-lifetime cubit: bound to the signed-in customer in main.dart.
  sl.registerLazySingleton<CartCubit>(
    () => CartCubit(
      watchCart: sl<WatchCart>(),
      setCartQuantity: sl<SetCartQuantity>(),
      removeFromCart: sl<RemoveFromCart>(),
      clearCart: sl<ClearCart>(),
    ),
  );
}

void _registerFavorites() {
  sl.registerLazySingleton<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(sl<FavoritesRemoteDataSource>()),
  );
  sl.registerLazySingleton<WatchFavorites>(
    () => WatchFavorites(sl<FavoritesRepository>()),
  );
  sl.registerLazySingleton<SetFavorite>(
    () => SetFavorite(sl<FavoritesRepository>()),
  );

  // App-lifetime cubit: bound to the signed-in customer in main.dart.
  sl.registerLazySingleton<FavoritesCubit>(
    () => FavoritesCubit(
      watchFavorites: sl<WatchFavorites>(),
      setFavorite: sl<SetFavorite>(),
    ),
  );
}

void _registerOrders() {
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(sl<OrderRemoteDataSource>()),
  );
  sl.registerLazySingleton<PlaceOrder>(() => PlaceOrder(sl<OrderRepository>()));
  sl.registerLazySingleton<WatchMyOrders>(
    () => WatchMyOrders(sl<OrderRepository>()),
  );
  sl.registerLazySingleton<WatchOrder>(() => WatchOrder(sl<OrderRepository>()));

  // Page-scoped cubits: a new instance per page, closed by BlocProvider.
  sl.registerFactory<CheckoutCubit>(
    () => CheckoutCubit(placeOrder: sl<PlaceOrder>()),
  );
  sl.registerFactoryParam<MyOrdersCubit, String, void>(
    (uid, _) => MyOrdersCubit(watchMyOrders: sl<WatchMyOrders>(), uid: uid),
  );
  sl.registerFactoryParam<OrderDetailsCubit, String, void>(
    (orderId, _) =>
        OrderDetailsCubit(watchOrder: sl<WatchOrder>(), orderId: orderId),
  );
}

void _registerRouter() {
  sl.registerLazySingleton<GoRouter>(() => AppRouter.create(sl<SessionCubit>()));
}
