import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF153B2F);
  static const Color ink = Color(0xFF0F1F1A);
  static const Color emerald = Color(0xFF153B2F);
  static const Color cream = Color(0xFFFBF6EC);
  static const Color amber = Color(0xFFF4B942);
  static const Color coral = Color(0xFFFF6B57);
  static const Color sage = Color(0xFFCFE3D6);
  static const Color teal = Color(0xFF2C7560);
  static const Color muted = Color(0xFF64736C);
  static const Color onDarkAccent = Color(0xFFFFFFFF);
  static const Color alertRed = Color(0xFF8E2D25);
  static const Color alertRedLight = Color(0xFFA63229);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppRadii {
  AppRadii._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 24;
  static const double xl = 28;
  static const double pill = 999;
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Book Store';
  static const String splashTagline = 'A good book is always in season.';
  static const String home = 'Home';
  static const String search = 'Search';
  static const String cart = 'Cart';
  static const String profile = 'Profile';
  static const String appearance = 'Appearance';
  static const String appearanceDescription =
      'Choose how the app looks on this device.';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String login = 'Log in';
  static const String register = 'Create account';
  static const String resetPassword = 'Reset password';
  static const String bookDetails = 'Book details';
  static const String checkout = 'Checkout';
  static const String wishlist = 'Wishlist';
  static const String orders = 'Orders';
  static const String adminDashboard = 'Admin dashboard';
  static const String manageBooks = 'Manage books';
  static const String manageOrders = 'Manage orders';
  static const String homeMessage = 'Your next favorite read is waiting.';
  static const String searchMessage =
      'Search for books by title, author, or genre.';
  static const String cartMessage =
      'Books you add to your cart will appear here.';
  static const String profileMessage =
      'Your profile and account settings will appear here.';
  static const String loginMessage =
      'Sign in to continue to your Book Store account.';
  static const String registerMessage =
      'Create an account to save your favorite reads.';
  static const String resetPasswordMessage =
      'Enter your email and we’ll send you a password reset link.';
  static const String bookDetailsMessage =
      'Book information and reviews will appear here.';
  static const String checkoutMessage =
      'Checkout will be available in a later phase.';
  static const String wishlistMessage = 'Books you save will appear here.';
  static const String ordersMessage =
      'Your completed and current orders will appear here.';
  static const String adminDashboardMessage =
      'Catalog and order tools will appear here.';
  static const String manageBooksMessage =
      'Catalog management will be available in a later phase.';
  static const String manageOrdersMessage =
      'Order management will be available in a later phase.';
  static const String noBooks = 'No books to show yet.';
  static const String retry = 'Try again';
  static const String errorTitle = 'Something went wrong';
  static const String genericError =
      'We couldn’t complete that request. Please try again.';
  static const String noInternetConnection = 'No internet connection';
  static const String permissionDeniedError =
      'Access was denied. Please check your permissions and try again.';
  static const String serviceUnavailableError =
      'The service is temporarily unavailable. Try again shortly.';
  static const String notFoundError = 'The requested item could not be found.';
  static const String unknownRouteTitle = 'Page not found';
  static const String unknownRouteMessage =
      'The page you requested is unavailable.';
  static const String goHome = 'Go Home';
  static const String startupError =
      'The app could not start. Please try again later.';
  static const String loading = 'Loading';
  static const String ratingLabel = 'Rating';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String continueLabel = 'Continue';
  static const String alreadyHaveAccount = 'Already have an account? Log in';
  static const String needAccount = 'New here? Create an account';
  static const String forgotPassword = 'Forgot password?';
  static const String previewStore = 'Continue to app preview';

  static const String loginHeading = 'Welcome back';
  static const String registerHeading = 'Join the Book Store';
  static const String resetPasswordHeading = 'Recover your account';
  static const String fullName = 'Full name';
  static const String confirmPassword = 'Confirm password';
  static const String continueWithGoogle = 'Continue with Google';
  static const String sendResetLink = 'Send reset link';
  static const String backToLogin = 'Back to log in';
  static const String logout = 'Log out';
  static const String logoutConfirmationTitle = 'Log out?';
  static const String logoutConfirmationMessage =
      'Are you sure you want to log out?';
  static const String cancel = 'Cancel';
  static const String accountNameUnavailable = 'Book Store reader';
  static const String passwordVisibilityShow = 'Show password';
  static const String passwordVisibilityHide = 'Hide password';
  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Enter a valid email address.';
  static const String shortPassword = 'Password must be at least 6 characters.';
  static const String passwordMismatch = 'Passwords do not match.';
  static const String registrationSuccess = 'Your account has been created.';
  static const String resetEmailSent =
      'If an account exists for this email, a reset link has been sent.';
  static const String authGenericError =
      'We couldn’t complete that request. Please try again.';
  static const String authNetworkError =
      'You appear to be offline. Check your connection and try again.';
  static const String authInvalidCredentials =
      'The email or password is incorrect.';
  static const String authEmailInUse =
      'An account already exists for this email.';
  static const String authWeakPassword =
      'Choose a stronger password with at least 6 characters.';
  static const String authInvalidEmail = 'Enter a valid email address.';
  static const String authUserNotFound = 'No account was found for that email.';
  static const String authUserDisabled =
      'This account has been disabled. Contact support for help.';
  static const String authTooManyRequests =
      'Too many attempts. Wait a little and try again.';
  static const String authProviderDisabled =
      'This sign-in method is not enabled yet.';
  static const String authPopupClosed =
      'The sign-in window was closed before finishing.';
  static const String authPopupBlocked =
      'Your browser blocked the sign-in window. Allow pop-ups and try again.';
  static const String authAccountConflict =
      'This email uses another sign-in method. Sign in with that method first.';
  static const String authGoogleCancelled = 'Google sign-in was cancelled.';
  static const String authPermissionDenied =
      'Access was denied. Check your Firebase security rules.';
  static const String authServiceUnavailable =
      'The service is temporarily unavailable. Try again shortly.';
  static const String catalogPermissionError =
      'Access to the book catalog was denied. Check the Firestore rules.';
  static const String catalogNetworkError =
      'The catalog could not load. Check your internet connection and try again.';
  static const String catalogGenericError =
      'We couldn’t load the catalog. Please try again.';
  static const String bookNotFound = 'This book could not be found.';
  static const String searchHint = 'Search titles, authors, or genres';
  static const String bestsellers = 'Bestsellers';
  static const String newArrivals = 'New Arrivals';
  static const String genres = 'Explore Genres';
  static const String browseAuthors = 'Browse by Author';
  static const String seeAll = 'See all';
  static const String browseBooks = 'Browse books';
  static const String noBooksAvailable =
      'No books are available yet. Ask an admin to seed the sample catalog.';
  static const String noBooksFound = 'No books found';
  static const String noBooksFoundMessage =
      'Try another search or clear your filters.';
  static const String filters = 'Filters & sort';
  static const String sortBy = 'Sort by';
  static const String filterGenre = 'Genre';
  static const String filterAuthor = 'Author';
  static const String priceRange = 'Price range';
  static const String allGenres = 'All genres';
  static const String allAuthors = 'All authors';
  static const String applyFilters = 'Apply filters';
  static const String clearFilters = 'Clear filters';
  static const String activeFilters = 'Active filters';
  static const String results = 'results';
  static const String priceLowToHigh = 'Price: low to high';
  static const String priceHighToLow = 'Price: high to low';
  static const String popularitySort = 'Most popular';
  static const String newestFirst = 'Newest first';
  static const String detailsTitle = 'Book details';
  static const String byLabel = 'by';
  static const String addToCart = 'Add to Cart';
  static const String addToWishlist = 'Add to Wishlist';
  static const String comingNextPhase = 'Coming in the next phase.';
  static const String reviews = 'Reviews';
  static const String reviewsComingLater =
      'Reviews will be available in a later phase.';
  static const String category = 'Category';
  static const String authorCategory = 'Books by author';
  static const String genreCategory = 'Books in genre';
  static const String seedSampleBooks = 'Seed sample books';
  static const String seedSuccess = 'Sample books were added to Firestore.';
  static const String seedSkipped =
      'Seeding skipped: the books collection is not empty.';
  static const String adminOnlySeed =
      'Only an admin can seed the sample catalog.';
  static const String browseCatalog = 'Browse catalog';
  static const String bookCountLabel = 'books';
  static const String noCategoryBooks =
      'No books are available in this category yet.';
  static const String minPrice = 'Min';
  static const String maxPrice = 'Max';
  static const String retryConnection = 'Check your connection and retry.';
  static const String loginRequiredForCart =
      'Log in to add books to your cart.';
  static const String loginRequiredForWishlist =
      'Log in to save books to your wishlist.';
  static const String catalogLoadFailed = 'Could not load the catalog.';
  static const String bookLoadFailed = 'Could not load this book.';
  static const String searchTab = 'Search tab';
  static const String closeLabel = 'Close';

  static const String unavailableBook = 'This book is no longer available.';
  static const String decreaseQuantity = 'Decrease quantity';
  static const String increaseQuantity = 'Increase quantity';
  static String checkoutTotal(String value) => '$checkout · $value';
  static const String checkoutStepAddress = 'Address';
  static const String checkoutStepPayment = 'Payment';
  static const String checkoutStepReview = 'Review';
  static const String statusProcessing = 'Processing';
  static const String bookFormDetails = 'Book details';
  static const String bookFormPricing = 'Pricing & visibility';
  static const String bookFormCover = 'Cover artwork';
  static const String replaceCover = 'Replace cover';
  static const String cartOperationFailed =
      'The cart could not be updated. Please try again.';
  static const String wishlistOperationFailed =
      'The wishlist could not be updated. Please try again.';
  static const String cartEmptyTitle = 'Your cart is empty';
  static const String cartEmptyMessage =
      'Find your next great read and add it here.';
  static const String orderSummary = 'Order summary';
  static const String itemCount = 'Items';
  static const String subtotal = 'Subtotal';
  static const String total = 'Total';
  static const String proceedToCheckout = 'Proceed to Checkout';
  static const String viewCart = 'View Cart';
  static const String remove = 'Remove';
  static const String undo = 'Undo';
  static const String quantity = 'Quantity';
  static const String inYourCart = 'In your cart';
  static const String wishlistRemove = 'Remove from Wishlist';
  static const String wishlistSaved = 'Saved to Wishlist';
  static const String wishlistRemoved = 'Removed from Wishlist';
  static const String moveToCart = 'Move to cart';
  static const String wishlistEmptyTitle = 'Your wishlist is empty';
  static const String wishlistEmptyMessage =
      'Save books you would love to read.';
  static const String editProfile = 'Edit profile';
  static const String editName = 'Edit name';
  static const String save = 'Save';
  static const String nameUpdated = 'Your name was updated.';
  static const String addressBook = 'Shipping addresses';
  static const String addAddress = 'Add address';
  static const String editAddress = 'Edit address';
  static const String deleteAddress = 'Delete address';
  static const String addressSaved = 'Address saved.';
  static const String addressDeleted = 'Address deleted.';
  static const String defaultAddressUpdated = 'Default address updated.';
  static const String setAsDefault = 'Set as default';
  static const String defaultLabel = 'Default';
  static const String label = 'Label';
  static const String homeAddress = 'Home';
  static const String workAddress = 'Work';
  static const String otherAddress = 'Other';
  static const String phone = 'Phone';
  static const String addressLine = 'Address line';
  static const String city = 'City';
  static const String postalCode = 'Postal code';
  static const String paymentMethods = 'Payment methods';
  static const String addPaymentMethod = 'Add payment method';
  static const String deletePaymentMethod = 'Delete payment method';
  static const String paymentMethodAdded = 'Payment method added.';
  static const String paymentMethodDeleted = 'Payment method deleted.';
  static const String paymentMethodDefaultUpdated =
      'Default payment method updated.';
  static const String card = 'Card';
  static const String cashOnDelivery = 'Cash on Delivery';
  static const String cardHolderName = 'Card holder name';
  static const String cardNumber = 'Card number';
  static const String expiryDate = 'Expiry date (MM/YY)';
  static const String paymentDemoNotice =
      'Demo only: real payments require a secure payment gateway. Card details are not charged or stored.';
  static const String profileNotFound = 'Your profile could not be found.';
  static const String profileSaveFailed =
      'Profile changes could not be saved. Please try again.';
  static const String profileLoadFailed =
      'Your profile details could not be loaded.';
  static const String addressValidationPhone = 'Enter a valid phone number.';
  static const String addressValidationPostal = 'Enter a valid postal code.';
  static const String cardNumberValidation = 'Enter a 16-digit card number.';
  static const String expiryValidation = 'Enter a valid expiry date.';
  static const String fullNameValidation = 'Enter your full name.';
  static const String deleteConfirmationTitle = 'Delete this item?';
  static const String deleteConfirmationMessage =
      'This action cannot be undone.';
  static const String checkoutSummary =
      'Review your books, delivery address, and payment method.';
  static const String paymentMethodType = 'Payment type';
  static const String initialsFallback = 'B';
  static const String unavailableItemsExcluded =
      'Unavailable books are excluded from the total.';
  static const String addedToCartMessage = 'Book added to your cart.';
  static const String movedToCartMessage = 'Book moved to your cart.';
  static const String noSavedDetails = 'No saved details yet.';
  static const String cartBadgeMaximum = '99+';
  static const String cartRemovedMessage = 'Item removed from your cart.';
  static const String unavailableLineTotal = '—';
  static const String maskedCardDigits = '••••';

  static const String loginRequiredForOrders = 'Log in to view your orders.';
  static const String loginRequiredForReviews =
      'Log in to write or like a review.';
  static const String orderOperationFailed =
      'The order could not be completed. Please try again.';
  static const String orderAlreadyPlacing =
      'Your order is already being placed.';
  static const String orderNotFound = 'This order could not be found.';
  static const String orderCannotCancel =
      'Only placed orders can be cancelled.';
  static const String orderInvalidPrice =
      'A book has an invalid price. Please contact support.';
  static const String checkoutNoAddress =
      'Add a shipping address before placing your order.';
  static const String checkoutNoItems =
      'Add at least one available book before checkout.';
  static const String checkoutLoadFailed =
      'Your saved checkout details could not be loaded.';
  static const String checkoutPlaceOrder = 'Place order';
  static const String addNewAddress = 'Add new address';
  static const String selectShippingAddress = 'Shipping address';
  static const String selectPaymentMethod = 'Payment method';
  static const String checkoutDemoNote =
      'Demo only: no real payment is processed.';
  static const String checkoutUnavailableItems =
      'Unavailable books were removed from this order.';
  static const String orderPlacedTitle = 'Order placed';
  static const String orderPlacedMessage = 'Your order is confirmed.';
  static const String orderNumber = 'Order number';
  static const String estimatedDelivery = 'Estimated delivery';
  static const String viewOrder = 'View order';
  static const String continueShopping = 'Continue shopping';
  static const String orderDetails = 'Order details';
  static const String orderHistory = 'My orders';
  static const String noOrdersTitle = 'No orders yet';
  static const String noOrdersMessage = 'Your placed orders will appear here.';
  static const String orderDate = 'Order date';
  static const String orderItems = 'Items';
  static const String shippingAddress = 'Shipping address';
  static const String paymentSummary = 'Payment';
  static const String orderTracking = 'Order tracking';
  static const String cancelOrder = 'Cancel order';
  static const String cancelOrderConfirmationTitle = 'Cancel this order?';
  static const String cancelOrderConfirmationMessage =
      'This order can only be cancelled before it ships.';
  static const String orderCancelledMessage = 'This order was cancelled.';
  static const String orderCancelSuccess = 'Order cancelled.';
  static String orderStatusUpdated(String status) =>
      'Order status updated to $status.';
  static const String statusPlaced = 'Placed';
  static const String statusShipped = 'Shipped';
  static const String statusOutForDelivery = 'Out for delivery';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';
  static const String orderIdUnavailable = 'Order details are not available.';
  static const String orderShortIdLabel = 'Order';
  static const String paymentCardEnding = 'Card ending in';
  static const String noSavedAddresses = 'No saved addresses';
  static const String addressRequired = 'A shipping address is required.';
  static const String reviewSummary = 'Average rating';
  static const String reviewSortNewest = 'Newest';
  static const String reviewSortMostLiked = 'Most liked';
  static const String writeReview = 'Write a review';
  static const String editYourReview = 'Edit your review';
  static const String deleteReview = 'Delete review';
  static const String reviewRatingLabel = 'Your rating';
  static const String reviewCommentLabel = 'Your review';
  static const String reviewCommentHint =
      'Share what you thought about this book';
  static const String reviewCommentValidation =
      'Write between 3 and 500 characters.';
  static const String reviewNameValidation =
      'Your display name must be 1 to 80 characters.';
  static const String reviewInvalidRating =
      'Choose a rating from 1 to 5 stars.';
  static const String reviewSave = 'Save review';
  static const String reviewSaved = 'Your review was saved.';
  static const String reviewDeleted = 'Your review was deleted.';
  static const String reviewDeleteConfirmationTitle = 'Delete your review?';
  static const String reviewDeleteConfirmationMessage =
      'This review will be removed.';
  static const String reviewLike = 'Like review';
  static const String reviewUnlike = 'Unlike review';
  static const String reviewEmptyTitle = 'No reviews yet';
  static const String reviewEmptyMessage = 'Be the first to review this book.';
  static const String reviewNotFound = 'This review could not be found.';
  static const String reviewCouldNotLoad = 'Reviews could not be loaded.';
  static const String reviewCannotLikeOwn = 'You cannot like your own review.';
  static const String reviewSaveFailed =
      'The review could not be saved. Please try again.';
  static const String noRatingDistribution = 'No ratings yet.';
  static String orderCountFormat(int count) => '$count orders';
  static String itemCountFormat(int count) => '$count items';
  static String orderStatusPlacedAt(String value) => '$statusPlaced: $value';
  static String orderStatusAt(String status, String value) => '$status: $value';
  static const String manageUsers = 'Manage users';
  static const String backToStore = 'Back to store';
  static const String adminSection = 'Administration';
  static const String totalBooks = 'Total books';
  static const String totalUsers = 'Total users';
  static const String totalOrders = 'Total orders';
  static const String totalRevenue = 'Total revenue';
  static const String lowRatedBooks = 'Low-rated books (< 3)';
  static const String recentOrders = 'Recent orders';
  static const String topBooks = 'Top books by popularity';
  static const String noRecentOrders = 'No orders yet.';
  static const String noPopularBooks = 'No books to rank yet.';
  static const String adminLoadFailed =
      'Admin data could not be loaded. Check your Firestore rules and try again.';
  static const String adminOperationFailed =
      'The admin action could not be completed. Please try again.';
  static const String addBook = 'Add book';
  static const String editBook = 'Edit book';
  static const String deleteBook = 'Delete book';
  static const String deleteBookConfirmation =
      'Delete this book? Existing orders will not be changed.';
  static const String bookSaved = 'Book saved.';
  static const String bookDeleted = 'Book deleted.';
  static const String bookTitle = 'Title';
  static const String bookAuthor = 'Author';
  static const String bookGenre = 'Genre';
  static const String bookDescription = 'Description';
  static const String bookPrice = 'Price';
  static const String releaseDate = 'Release date';
  static const String selectReleaseDate = 'Choose release date';
  static const String clearReleaseDate = 'Clear date';
  static const String bestseller = 'Bestseller';
  static const String popularity = 'Popularity';
  static const String coverImage = 'Cover image';
  static const String pickCoverImage = 'Choose image';
  static const String coverImageUrl = 'Cover image URL';
  static const String coverImageHelp =
      'Upload an image or enter a public image URL.';
  static const String storageUploadFailed =
      'Storage upload failed. If Storage is not enabled or requires a paid plan, use the Cover image URL field instead.';
  static const String invalidCoverUrl = 'Enter a valid image URL.';
  static const String addNewGenre = 'Add new genre';
  static const String newGenre = 'New genre';
  static const String searchBooks = 'Search books';
  static const String filterBooksByGenre = 'Filter by genre';
  static const String allBooks = 'All books';
  static const String noManagedBooks = 'No books match your filters.';
  static const String priceValidation = 'Enter a price greater than zero.';
  static const String integerValidation =
      'Enter a whole number greater than or equal to zero.';
  static const String orderId = 'Order ID';
  static const String customer = 'Customer';
  static const String orderStatus = 'Status';
  static const String filterOrdersByStatus = 'Filter by status';
  static const String allStatuses = 'All statuses';
  static const String searchOrders = 'Search order ID or customer';
  static const String noManagedOrders = 'No orders match your filters.';
  static const String updateOrderStatus = 'Update order status';
  static const String confirmStatusChange = 'Confirm status change?';
  static const String statusChangeConfirmation =
      'The customer will see this update in their order tracking.';
  static const String invalidOrderTransition =
      'That order status change is not allowed.';
  static const String orderStatusSaved = 'Order status updated.';
  static const String orderCustomer = 'Customer details';
  static const String orderItemsTotal = 'Order total';
  static const String joinedDate = 'Joined';
  static const String role = 'Role';
  static const String userRole = 'User';
  static const String adminRole = 'Admin';
  static const String changeRole = 'Change role';
  static const String disableAccount = 'Disable account';
  static const String enableAccount = 'Enable account';
  static const String accountDisabled = 'Disabled';
  static const String accountEnabled = 'Enabled';
  static const String disableAccountConfirmation =
      'Disable this account in the app?';
  static const String enableAccountConfirmation = 'Re-enable this account?';
  static const String roleChangeConfirmation = 'Change this user’s role?';
  static const String userUpdated = 'User updated.';
  static const String userDetails = 'User details';
  static const String orderCount = 'Order count';
  static const String totalSpent = 'Total spent';
  static const String noUsersFound = 'No users match your search.';
  static const String searchUsers = 'Search users by name or email';
  static const String selfRoleChangeBlocked =
      'You cannot change your own admin role.';
  static const String selfDisableBlocked =
      'You cannot disable your own account.';
  static const String lastAdminBlocked =
      'At least one admin account must remain.';
  static const String appLevelDisableNote =
      'Firestore and Storage rules block disabled accounts from protected data, but the Firebase Auth session is not revoked. Full account enforcement requires Cloud Functions or the Firebase Admin SDK.';
  static const String adminAccountDisabledNotice =
      'Your account has been disabled.';
  static const String noData = '—';
  static const String booksTab = 'Books';
  static const String usersTab = 'Users';
  static const String dashboardTab = 'Dashboard';
  static const String welcomeBack = 'Welcome back';
  static const String featuredBook = 'Editor’s pick';
  static const String discoverBook = 'Discover this book';
  static const String featuredBooks = 'Featured books';
  static String featuredPageFormat(int current, int total) =>
      'Book $current of $total';
  static const String newLabel = 'NEW';
  static const String readMore = 'Read more';
  static const String readLess = 'Read less';
  static const String ratingStarsLabel = 'Stars';
  static String reviewCountFormat(int count) =>
      count == 1 ? '1 review' : '$count reviews';
  static String bookRankFormat(int rank) => 'Rank $rank';
  static const String savedReads = 'Saved reads';
  static const String homeSubtitle = 'Find a little wonder between the pages.';
  static const String loadingUpload = 'Uploading cover';
  static String statusCount(String status, int count) => '$status: $count';
  static String booksMatchCount(int count) => '$count books';
  static String ordersMatchCount(int count) => '$count orders';
  static String revenueForCount(int count) => '$count orders';
  static String userOrdersCount(int count) => '$count';
}
