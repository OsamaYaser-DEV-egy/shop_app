# Stages 1 and 2 setup (project setup, then authentication, profiles and role routing)

Copy `lib/`, `test/`, `analysis_options.yaml` and `firestore.rules` into a project created with:

```bash
flutter create --org com.example --platforms=android shop_app
cd shop_app
```

## Runtime dependencies

```bash
flutter pub add firebase_core firebase_auth cloud_firestore cloud_functions firebase_messaging
flutter pub add flutter_bloc equatable get_it go_router
flutter pub add cached_network_image flutter_local_notifications intl shared_preferences
```

## Dev dependencies

```bash
flutter pub add --dev flutter_lints mocktail bloc_test fake_cloud_firestore firebase_auth_mocks
```

## Firebase project setup

1. Create a project in the Firebase console.
2. Authentication > Sign-in method: enable **Email/Password**.
3. Firestore Database: create a database (production mode).
4. Generate the config files (not included in this source):

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

5. Deploy the Stage 1 rules:

```bash
firebase init firestore     # choose the existing firestore.rules, accept defaults
firebase deploy --only firestore:rules
```

## Creating the first admin securely

Customers can only create a profile with `role: "customer"`, and the rules block any later role change from the app. To make an admin:

1. Register the account normally in the app.
2. Firebase console > Firestore Database > `users` > the account's document (its ID is the Auth UID).
3. Edit the `role` field from `customer` to `admin`.

Console edits are made with your project-owner credentials, so they bypass the client rules. Restart the app (or sign out and in) to see the dashboard. A script using the Admin SDK will be added with the Cloud Functions stage.

## Validate

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Expected behaviour:
- Signed out: login screen. Register creates the account and profile, then the app moves to the home screen on its own.
- Customer: home screen with a profile icon. Admin: admin dashboard only.
- Deleting the `users/{uid}` document of a signed-in account shows "Account setup incomplete" after about 8 seconds.

# Stage 4 setup (cart and favorites; Stage 3 in the requirements document)

No new packages. Deploy the updated rules, which add `users/{uid}/cart` and `users/{uid}/favorites`:

```bash
firebase deploy --only firestore:rules
```

Data model:
- `users/{uid}/cart/{productId}`: `{ productId, quantity: 1..99, updatedAt }`. Names, prices and stock are always read live from `products`; the order function in Stage 5 re-checks them on the server.
- `users/{uid}/favorites/{productId}`: `{ productId, addedAt }`.

Expected behaviour (customer accounts only):
- Home and product pages show a cart button with a badge, and a heart on every product.
- Product page: "Add to cart" adds one unit at a time, up to the stock.
- Cart page: change quantities, remove items, clear the cart. Deleted, unavailable or over-stock items are flagged and left out of the subtotal.
- Favorites page lists saved products. Signing out clears both from the app.

# Stage 5 setup (checkout and orders; Stage 4 in the requirements document)

No new packages, and no Cloud Functions: the project stays on the free Spark plan. Deploy the updated rules:

```bash
firebase deploy --only firestore:rules
```

How an order is placed (`OrderRemoteDataSource.placeOrder`): one Firestore transaction reads the ordered products, checks availability and stock, lowers each product's `stock` (and sets `lastOrderId`), creates `orders/{orderId}` and deletes the ordered cart items. The Security Rules accept it only if:
- every item's `name` and `price` equal the product's current values, and the `totalPrice` equals the sum (within one cent);
- each product's stock drops by exactly the ordered quantity, linked to an order created by the same user in the same request;
- the order is `pending`, Cash on Delivery, and belongs to the signed-in user.

Customers can read only their own orders and cannot change them. One order can hold up to 8 different products (any quantity of each), the most the rules can check within Firestore's per-request limits.

Order document: `{ userId, customerName, customerEmail, items: { <productId>: { name, price, quantity } }, totalPrice, shippingAddress, phone, paymentMethod: "cash_on_delivery", status, createdAt, updatedAt }`.

## Testing the rules

`firestore_tests/` runs the rules in the Firestore emulator (needs Node and Java 11+):

```bash
cd firestore_tests
npm install
npm test
```

On Windows, if the emulator fails with "Unable to establish loopback connection", the temp path is too long for Java; set `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\tmp` (any short existing folder) and run again.

# Stage 6 setup (admin orders; Stage 5 in the requirements document)

No new packages. Deploy the updated rules:

```bash
firebase deploy --only firestore:rules
```

Admin: Dashboard > Orders lists all orders (newest 200) with a status filter. Opening one shows the customer, items, delivery details and the allowed actions.

Business rules, enforced by `firestore.rules` and mirrored in `OrderStatus`:
- The store moves an order forward one step at a time: pending → confirmed → preparing → shipped → delivered.
- The store can cancel an order until it ships. A customer can cancel their own order while it is pending (Order details > Cancel order).
- A status change may touch only `status` and `updatedAt`. Orders are never deleted.
- Cancelling returns each item's quantity to stock in the same transaction. The rules allow a product's stock to rise only by the cancelled quantity, once, and only while that order turns cancelled (`lastRestockOrderId` links the two). Items whose product was deleted are skipped.

The rules tests in `firestore_tests/` cover these cases (`npm test`).

# Stage 7 setup (notifications; Stage 6 in the requirements document)

The project stays on the free Spark plan with no server, so notifications are **in-app and local**: they appear while the app is running (open or in the background), not when it is closed. Deploy the updated rules:

```bash
firebase deploy --only firestore:rules
```

How it works:
- When the admin confirms, ships, delivers or cancels an order, the same Firestore transaction writes `notifications/{id}`: `{ userId, orderId, status, title, body, isRead, createdAt }`. The rules check that it matches the order (customer, new status) and that only admins create it.
- The customer's app watches its notifications. New ones are shown as Android notifications (channel "Order updates"); older ones only appear in the list. The bell on Home shows the unread count and opens the notification list.
- Tapping a notification (system tray or list) marks it read and opens the order. If the tap starts the app, the order opens once the customer is signed in.
- Customers can only read their own notifications and mark them read. Notifications are never deleted.
- Android 13+ asks for notification permission the first time a customer signs in.

Limits (accepted for v1): no push when the app is closed (Firebase Cloud Messaging would need Cloud Functions or another trusted server); Android may stop the app's connection after some time in the background. Missed updates are still in the notification list and on the order screen.

# Stage 8: final review (Stage 7 in the requirements document)

- Security Rules reviewed: profile `updatedAt` must now be the server time; header rewritten as a map of the collections. `firestore_tests/` covers all collections (62 tests), including role escalation, private profiles and product permissions.
- `firebase.json` now has the `firestore.rules` target and `.firebaserc` names the default project, so `firebase deploy --only firestore:rules` works from the project folder.
- Error handling: global handlers for uncaught errors (logged; a friendly message replaces broken widgets in release builds); friendly messages for Firestore quota (`resource-exhausted`), timeouts and transaction conflicts.
- Removed unused packages and code from the dropped Cloud Functions/FCM plans (`cloud_functions`, `firebase_messaging`, `firebase_storage`, `image_picker`).
- `flutter analyze` reports no issues (`prefer_initializing_formals` is disabled on purpose, see `analysis_options.yaml`).
- Widget tests for cart lines, order details and the notification list; error mapping tests. A widget test found and fixed a bug: tapping a disabled quantity button opened the product page.
- README rewritten: features, setup, data model, security model, notifications, tests and known limitations.
