# Book Store — Phase 1 Foundation

This bundle contains the complete Phase 1 `lib/` source and `pubspec.yaml` for a Flutter project named `book_store`. It targets Flutter web (Chrome) and Android phones. Authentication, catalog loading, cart behavior, and admin actions are deliberately not implemented in this phase.

## Project files

- `pubspec.yaml`
- `lib/main.dart`, `lib/app.dart`, `lib/firebase_options.dart`
- `lib/core/`: constants, theme, routes, router, utilities
- `lib/models/`: Book, AppUser, CartItem, Order, Review, WishlistItem
- `lib/services/`: abstract service contracts
- `lib/providers/`: Provider state placeholders
- `lib/screens/`: splash, auth, tab, checkout, profile, and admin placeholders
- `lib/widgets/`: reusable cards, fields, buttons, states, and rating widget

## Manual steps

1. Install the latest stable Flutter SDK and add `flutter` to `PATH`.
2. Create a Firebase project in the Firebase Console. Add a Web app and an Android app (the Android package name should match the generated Flutter project's `applicationId`).
3. From a terminal, create the platform scaffolding:

   ```sh
   flutter create --platforms=web,android book_store
   ```

4. Copy/merge this bundle's `pubspec.yaml` and `lib/` into `book_store/`, replacing the generated versions.
5. In Firebase Console, open **Authentication → Get started → Sign-in method**, enable **Email/Password**, and save. Open **Firestore Database → Create database** and finish the setup.
6. In the project directory, configure the Firebase apps and generate Flutter options:

   ```sh
   cd book_store
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   `flutterfire configure` replaces `lib/firebase_options.dart` with project-specific options. The included placeholder is only for a compilable starter and must be replaced before connecting Firebase services.
7. No Firebase Storage setup is required for this UI-only phase. Enable it when implementing image uploads.

## How to run

```sh
cd book_store
flutter pub get
flutter run -d chrome
```

For a USB-connected Android phone, enable Developer options and USB debugging, accept the device authorization prompt, then run:

```sh
flutter devices
flutter run -d <device-id>
```

## Phase 1 verification checklist

- [ ] `flutter pub get` completes.
- [ ] `flutter run -d chrome` opens the app without compile/runtime errors.
- [ ] Splash screen shows the Book Store brand for two seconds, then opens Login.
- [ ] Login links open Register and Reset Password placeholders.
- [ ] Bottom navigation switches among Home, Search, Cart, and Profile.
- [ ] All routes are named and the admin, wishlist, orders, details, and checkout routes build.
- [ ] Models round-trip Firestore-compatible maps and support `copyWith`.
- [ ] BookCard, form field, button, loading, rating, error, and empty-state widgets are available.
- [ ] After `flutterfire configure`, Firebase initializes with your web and Android app options.

## Phase 3 — Book Catalog, Search, and Filters

Phase 3 adds a Firestore-backed public catalog, cached provider state, Home and Search experiences, genre/author category pages, book details, and an admin-only sample catalog seed action. Catalog reads are public; Firestore writes remain admin-only. No Firestore composite index is required because sorting and filtering run on the client.

### Manual setup and seed

1. Confirm Firebase Authentication and Firestore are enabled and that `lib/firebase_options.dart` points to the Firebase project you intend to use.
2. Sign up or sign in with the account that will administer the catalog. In Firebase Console, open **Authentication → Users**, copy that account's UID, then open **Firestore Database → Data** and create/update `users/{UID}` with the string field `role` set to `admin`. Keep the document ID equal to the Firebase Auth UID. Sign out and sign back in so the app reloads the role.
3. The signed-in admin opens the Admin dashboard and selects **Seed sample books**. Seeding writes 18 records in one batched write. It safely skips if the `books` collection already contains any document. The seed button is hidden for non-admin users.
4. The bundled `firestore.rules` already allows public reads from `books` and allows writes only when the caller's user document has `role: "admin"`. No Phase 3 rule change is needed. If these rules have not been published to your Firebase project, publish the included rules with `firebase deploy --only firestore:rules` after selecting the correct Firebase project, or paste the bundled rules in Firebase Console → Firestore Database → Rules. Do not loosen the admin write rule.

### How to run

The portable archive omits the generated `android/local.properties` and Gradle cache so machine-specific SDK paths are not carried over; Flutter recreates local Android settings when you build. Ensure your Android SDK is installed and accepted in `flutter doctor`.

```sh
flutter pub get
flutter analyze
flutter run -d chrome
```

For an Android phone, enable USB debugging, connect and authorize the device, then run:

```sh
flutter devices
flutter run -d <device-id>
```

### Phase 3 manual verification checklist

- [ ] Sign in as an admin and seed the sample books; confirm success, then confirm a second seed attempt skips because the collection is non-empty.
- [ ] Home shows horizontally scrolling Bestsellers and New Arrivals, genre chips, and Browse by Author; pull down to refresh.
- [ ] Tapping a genre chip or author opens the matching Category screen.
- [ ] Open a book and verify cover, title, tappable author, genre, price, rating/count, full description, and Reviews placeholder.
- [ ] Search by title, author, and genre; verify partial and case-insensitive matches.
- [ ] Verify price low-to-high, price high-to-low, popularity, and newest-first sorting.
- [ ] Apply a price range, then clear the price chip; clear all filters and confirm the full catalog returns.
- [ ] Test a failed/offline catalog read and verify an actionable error with Retry.
- [ ] Sign out and verify Home, Search, details, and Category remain browseable; Add to Cart and Add to Wishlist redirect to Login.
- [ ] Confirm the seed action is not visible to non-admin users and the Firestore write rule remains admin-only.
