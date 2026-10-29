# Shop App

A mobile e-commerce app built with **Flutter** and **Firebase** (Authentication + Cloud Firestore). Customers browse products, keep favorites and a cart, place Cash on Delivery orders and follow their status; admins manage products and process orders.

It runs entirely on Firebase's free **Spark plan**: there are no Cloud Functions, so the **Firestore Security Rules are the trusted authority**. They verify prices, totals, stock changes and order statuses, and they are tested in the Firestore emulator.

## Features

**Customers**
- Register, log in, log out, reset a forgotten password; profile with name, phone and delivery address
- Product catalog with search by name, category filter, featured products and live stock
- Favorites and a cart stored in Firestore (kept across devices and app restarts)
- Checkout with Cash on Delivery: review items, confirm phone and address, place the order
- Order success screen, My Orders, order details with live status, cancel while pending
- Order notifications (confirmed, shipped, delivered, cancelled) with an in-app notification list

**Admins**
- Dashboard with product management (create, edit, delete) and orders
- Order list with status filter; order details with customer, items and delivery info
- Move orders forward one step at a time (pending → confirmed → preparing → shipped → delivered) or cancel them before they ship; cancelling returns stock

Roles come only from the `role` field of the user's Firestore profile. Customers can never make themselves admin (enforced by the rules, not by hiding buttons).

## Tech stack

| Area | Choice |
|---|---|
| UI | Flutter (Material 3, dark theme), Android first |
| State | `flutter_bloc` (Cubits) + `equatable` |
| Navigation | `go_router`, with role-based redirects in one tested function |
| Dependency injection | `get_it` |
| Backend | Firebase Authentication (email/password), Cloud Firestore |
| Notifications | `flutter_local_notifications` (in-app, see [Notifications](#notifications)) |
| Tests | `flutter_test` + `mocktail`; Security Rules tests with `@firebase/rules-unit-testing` |

## Project structure

```
lib/
  core/            DI, routing, theme, errors, notifications, shared widgets
  features/
    auth/          sign-in, registration, session (who is signed in, which role)
    profile/       profile entity and editing
    products/      catalog, product details, admin product management
    cart/          cart and checkout summary
    favorites/     saved products
    orders/        checkout, orders, status rules, admin order screens
    notifications/ notification list and local notifications
    admin/         admin dashboard and pages
test/              unit and widget tests
firestore.rules    Security Rules
firestore_tests/   Security Rules tests (Firestore emulator)
```

Each feature is split into `data` (Firestore), `domain` (entities, use cases, business rules) and `presentation` (cubits, pages, widgets).

## Getting started

### 1. Requirements
- Flutter 3.47 or newer (Dart 3.13+)
- An Android device or emulator
- Node.js and the Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### 2. Firebase project
1. Create a project in the [Firebase console](https://console.firebase.google.com) (the Spark plan is enough).
2. **Authentication** → Sign-in method → enable **Email/Password**.
3. **Firestore Database** → create a database in production mode.
4. Connect the app (generates `lib/firebase_options.dart` and `android/app/google-services.json`, which are not committed):
   ```bash
   firebase login
   flutterfire configure
   ```
5. Point the Firebase CLI at your project (replace the id in `.firebaserc`, or run `firebase use --add`), then deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 3. Run
```bash
flutter pub get
flutter run
```

### 4. Create the first admin
Register normally in the app, then in the Firebase console open **Firestore → users → (your user id)** and change `role` from `customer` to `admin`. Sign out and in again to see the admin dashboard. (Console edits use your owner account, so they bypass the client rules; the app itself can never do this.)

Add some products from the admin dashboard, then sign in with a customer account to shop.

## Data model

| Path | Fields |
|---|---|
| `users/{uid}` | `name, email, phone, address, role, createdAt, updatedAt` |
| `products/{id}` | `name, description, price, imageUrl, category, stock, isAvailable, isFeatured, createdAt, updatedAt` (+ `lastOrderId`, `lastRestockOrderId` written by orders) |
| `users/{uid}/cart/{productId}` | `productId, quantity, updatedAt` |
| `users/{uid}/favorites/{productId}` | `productId, addedAt` |
| `orders/{id}` | `userId, customerName, customerEmail, items, totalPrice, shippingAddress, phone, paymentMethod, status, createdAt, updatedAt` |
| `notifications/{id}` | `userId, orderId, status, title, body, isRead, createdAt` |

`items` is a map keyed by product id: `{ <productId>: { name, price, quantity } }`. Name and price are copied at purchase time, so past orders never change when a product is edited.

## How orders stay trustworthy without a server

Placing an order is **one Firestore transaction** from the app: it reads the products, checks availability and stock, lowers each product's stock, creates the order and empties the cart. The rules accept it only if:
- each item's name and price equal the product's current values, and `totalPrice` equals their sum;
- each product's stock drops by exactly the quantity ordered, tied to an order created by the same user in the same request;
- the order is `pending`, Cash on Delivery, and belongs to the signed-in user.

Afterwards only the status can change: customers may cancel their own pending order, admins move it one step forward or cancel it before shipping. Cancelling returns the stock, and the rules allow that only once and only by the cancelled quantities. Orders are never deleted.

One order can contain up to **8 different products** (any quantity of each): the rules check every item, and that is the most that fits in Firestore's per-request rule limits.

## Notifications

When an admin confirms, ships, delivers or cancels an order, the same transaction writes a document in `notifications`. The customer's app watches it and:
- shows new ones as Android notifications while the app is running (open or in the background);
- keeps all of them in the notification list (bell on the home screen, with an unread count);
- opens the order when a notification is tapped.

**Limit:** nothing is pushed while the app is closed. True push (Firebase Cloud Messaging) would need Cloud Functions (Blaze plan) or another trusted server holding the sending credentials, which this version deliberately avoids. Missed updates are still in the notification list and on the order screen.

## Tests

```bash
flutter test
```
Unit and widget tests for business rules, cubits, models, routing redirects and key screens.

```bash
cd firestore_tests
npm install
npm test
```
Runs `firestore.rules` in the Firestore emulator (needs Java 11+): role escalation, private data, price and total tampering, stock changes, status rules, cancellations and notifications. On Windows, if the emulator fails with "Unable to establish loopback connection", set `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\tmp` (any short existing folder) and run again.

## Building a release

```bash
flutter build apk --release --split-per-abi
```
The release build is currently signed with the debug key (`android/app/build.gradle.kts`). Before publishing, create your own signing key and change the application id from `com.example.shop_app` (which also means registering the new id in Firebase).

## Known limitations

- No push notifications while the app is closed (see [Notifications](#notifications)).
- Up to 8 different products per order.
- The admin order list shows the newest 200 orders.
- Payment is Cash on Delivery only; there is no online payment, coupons or courier tracking (out of scope for version 1).
- Android is the tested platform; iOS would need its own Firebase app and notification setup.

[STAGE1_SETUP.md](STAGE1_SETUP.md) has stage-by-stage development notes.
