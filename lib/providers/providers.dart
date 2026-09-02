import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final currentDriverProfileProvider = StreamProvider<DriverProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).watchDriverProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Live stream of orders for the currently signed-in customer.
final customerOrdersProvider = StreamProvider<List<KgoroOrder>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).watchCustomerOrders(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Live stream of rides for the currently signed-in customer.
final customerRidesProvider = StreamProvider<List<RideRequest>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).watchCustomerRides(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Active (in-progress) orders for the home screen ActiveOrderCard.
/// Returns the most recently created order that is not yet delivered/cancelled.
final activeOrderProvider = Provider<KgoroOrder?>((ref) {
  final ordersAsync = ref.watch(customerOrdersProvider);
  final orders = ordersAsync.valueOrNull ?? [];
  final activeStatuses = {
    OrderStatus.pending,
    OrderStatus.matched,
    OrderStatus.accepted,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
  };
  final active = orders.where((o) => activeStatuses.contains(o.status)).toList();
  if (active.isEmpty) return null;
  // Already sorted newest-first from Firestore
  return active.first;
});

/// Live stream of a vendor's incoming orders, keyed by vendorId.
final vendorOrdersProvider =
    StreamProvider.family<List<KgoroOrder>, String>((ref, vendorId) {
  return ref.watch(firestoreServiceProvider).watchVendorOrders(vendorId);
});

/// Connectivity state — true when the device has any network access.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
});

/// Cart state — kept simple (in-memory, per-vendor) since orders are
/// single-vendor. A future iteration could persist this locally with
/// shared_preferences for cart recovery after app kill.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);
  String? vendorId;

  void addProduct(Product product) {
    if (vendorId != null && vendorId != product.vendorId) {
      // switching vendor clears the cart — mirrors most delivery apps'
      // "start a new order?" behaviour, simplified here.
      state = [];
    }
    vendorId = product.vendorId;
    final index = state.indexWhere((c) => c.product.id == product.id);
    if (index >= 0) {
      // Build an entirely new list with the updated quantity — never mutate
      // the existing list or its elements as Riverpod tracks identity.
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            CartItem(product: state[i].product, quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeProduct(String productId) {
    state = state.where((c) => c.product.id != productId).toList();
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeProduct(productId);
      return;
    }
    state = [
      for (final c in state)
        if (c.product.id == productId) CartItem(product: c.product, quantity: qty) else c
    ];
  }

  double get total => state.fold(0, (sum, c) => sum + c.subtotal);

  void clear() {
    state = [];
    vendorId = null;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

final selectedServiceTabProvider = StateProvider<int>((ref) => 0);
