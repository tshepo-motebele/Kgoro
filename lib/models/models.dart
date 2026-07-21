import '../core/constants.dart';

enum UserRole { customer, driver, vendor, admin }

class AppUser {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String localArea;
  final double? homeLat;
  final double? homeLng;
  final bool isResidencyVerified;
  final UserRole role;
  final double rating;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.localArea,
    this.homeLat,
    this.homeLng,
    this.isResidencyVerified = false,
    this.role = UserRole.customer,
    this.rating = 5.0,
    required this.createdAt,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        fullName: map['fullName'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'],
        localArea: map['localArea'] ?? '',
        homeLat: (map['homeLat'] as num?)?.toDouble(),
        homeLng: (map['homeLng'] as num?)?.toDouble(),
        isResidencyVerified: map['isResidencyVerified'] ?? false,
        role: UserRole.values.elementAtOrNull(map['role'] ?? 0) ?? UserRole.customer,
        rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
        createdAt:
            DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'localArea': localArea,
        'homeLat': homeLat,
        'homeLng': homeLng,
        'isResidencyVerified': isResidencyVerified,
        'role': role.index,
        'rating': rating,
        'createdAt': createdAt.toIso8601String(),
      };

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? localArea,
    double? homeLat,
    double? homeLng,
    bool? isResidencyVerified,
    UserRole? role,
    double? rating,
  }) =>
      AppUser(
        id: id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        localArea: localArea ?? this.localArea,
        homeLat: homeLat ?? this.homeLat,
        homeLng: homeLng ?? this.homeLng,
        isResidencyVerified: isResidencyVerified ?? this.isResidencyVerified,
        role: role ?? this.role,
        rating: rating ?? this.rating,
        createdAt: createdAt,
      );
}

/// A driver/rider-partner profile. Separate from AppUser so someone can
/// be a customer first and apply to become a driver later.
class DriverProfile {
  final String userId;
  final VehicleType vehicleType;
  final String idNumber;
  final String proofOfAddressUrl;
  final String idDocumentUrl;
  final String? selfieUrl;
  final List<String> vouchedByUserIds;
  final ApprovalStatus approvalStatus;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;
  final double rating;
  final int completedJobs;
  final int cancelledJobs;
  final int acceptedOffers;
  final int totalOffers;
  final DateTime? lastJobCompletedAt;
  final double earningsThisWeek;
  final DateTime appliedAt;

  DriverProfile({
    required this.userId,
    required this.vehicleType,
    required this.idNumber,
    required this.proofOfAddressUrl,
    required this.idDocumentUrl,
    this.selfieUrl,
    this.vouchedByUserIds = const [],
    this.approvalStatus = ApprovalStatus.pendingReview,
    this.isOnline = false,
    this.currentLat,
    this.currentLng,
    this.rating = 5.0,
    this.completedJobs = 0,
    this.cancelledJobs = 0,
    this.acceptedOffers = 0,
    this.totalOffers = 0,
    this.lastJobCompletedAt,
    this.earningsThisWeek = 0,
    required this.appliedAt,
  });

  double get acceptanceRate =>
      totalOffers == 0 ? 1.0 : acceptedOffers / totalOffers;

  /// Minutes since last completed job — fairness term of the matching algorithm.
  int get minutesSinceLastJob {
    if (lastJobCompletedAt == null) return 1 << 20;
    return DateTime.now().difference(lastJobCompletedAt!).inMinutes;
  }

  factory DriverProfile.fromMap(String userId, Map<String, dynamic> map) =>
      DriverProfile(
        userId: userId,
        vehicleType: VehicleType.values[map['vehicleType'] ?? 0],
        idNumber: map['idNumber'] ?? '',
        proofOfAddressUrl: map['proofOfAddressUrl'] ?? '',
        idDocumentUrl: map['idDocumentUrl'] ?? '',
        selfieUrl: map['selfieUrl'],
        vouchedByUserIds: List<String>.from(map['vouchedByUserIds'] ?? []),
        approvalStatus:
            ApprovalStatus.values[map['approvalStatus'] ?? 0],
        isOnline: map['isOnline'] ?? false,
        currentLat: (map['currentLat'] as num?)?.toDouble(),
        currentLng: (map['currentLng'] as num?)?.toDouble(),
        rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
        completedJobs: map['completedJobs'] ?? 0,
        cancelledJobs: map['cancelledJobs'] ?? 0,
        acceptedOffers: map['acceptedOffers'] ?? 0,
        totalOffers: map['totalOffers'] ?? 0,
        lastJobCompletedAt: map['lastJobCompletedAt'] != null
            ? DateTime.tryParse(map['lastJobCompletedAt'])
            : null,
        earningsThisWeek:
            (map['earningsThisWeek'] as num?)?.toDouble() ?? 0,
        appliedAt: DateTime.tryParse(map['appliedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'vehicleType': vehicleType.index,
        'idNumber': idNumber,
        'proofOfAddressUrl': proofOfAddressUrl,
        'idDocumentUrl': idDocumentUrl,
        'selfieUrl': selfieUrl,
        'vouchedByUserIds': vouchedByUserIds,
        'approvalStatus': approvalStatus.index,
        'isOnline': isOnline,
        'currentLat': currentLat,
        'currentLng': currentLng,
        'rating': rating,
        'completedJobs': completedJobs,
        'cancelledJobs': cancelledJobs,
        'acceptedOffers': acceptedOffers,
        'totalOffers': totalOffers,
        'lastJobCompletedAt': lastJobCompletedAt?.toIso8601String(),
        'earningsThisWeek': earningsThisWeek,
        'appliedAt': appliedAt.toIso8601String(),
      };
}

class Vendor {
  final String id;
  final String name;
  final ServiceType type;
  final String imageUrl;
  final String localArea;
  final double lat;
  final double lng;
  final bool isOpen;
  final double rating;
  final ApprovalStatus approvalStatus;

  // New fields (§4 & §6)
  final String? ownerId;        // uid of the user who registered the store
  final String? address;        // physical street address
  final String? contactPhone;
  final Map<String, String> openingHours; // e.g. {'Mon': '08:00-20:00'}
  final bool isChainBrand;      // true for Shoprite-scale multi-branch vendors

  Vendor({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.localArea,
    required this.lat,
    required this.lng,
    this.isOpen = true,
    this.rating = 4.5,
    this.approvalStatus = ApprovalStatus.pendingReview,
    this.ownerId,
    this.address,
    this.contactPhone,
    this.openingHours = const {},
    this.isChainBrand = false,
  });

  factory Vendor.fromMap(String id, Map<String, dynamic> map) => Vendor(
        id: id,
        name: map['name'] ?? '',
        type: ServiceType.values[map['type'] ?? 0],
        imageUrl: map['imageUrl'] ?? '',
        localArea: map['localArea'] ?? '',
        lat: (map['lat'] as num?)?.toDouble() ?? 0,
        lng: (map['lng'] as num?)?.toDouble() ?? 0,
        isOpen: map['isOpen'] ?? true,
        rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
        approvalStatus: ApprovalStatus.values[map['approvalStatus'] ?? 0],
        ownerId: map['ownerId'],
        address: map['address'],
        contactPhone: map['contactPhone'],
        openingHours: Map<String, String>.from(map['openingHours'] ?? {}),
        isChainBrand: map['isChainBrand'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.index,
        'imageUrl': imageUrl,
        'localArea': localArea,
        'lat': lat,
        'lng': lng,
        'isOpen': isOpen,
        'rating': rating,
        'approvalStatus': approvalStatus.index,
        'ownerId': ownerId,
        'address': address,
        'contactPhone': contactPhone,
        'openingHours': openingHours,
        'isChainBrand': isChainBrand,
      };
}

class Product {
  final String id;
  final String vendorId;
  final String name;
  final double price;
  final String imageUrl;
  final String category;

  // §6: quantity replaces bool inStock; inStock is derived
  final int quantity;
  final String? sku;
  final int lowStockThreshold; // badge shown when quantity <= this

  Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.quantity = 0,
    this.sku,
    this.lowStockThreshold = 5,
  });

  /// Backward-compat: derive from quantity. Old docs with inStock:bool
  /// still work because fromMap falls back to quantity=1 when inStock==true.
  bool get inStock => quantity > 0;
  bool get isLowStock => quantity > 0 && quantity <= lowStockThreshold;

  factory Product.fromMap(String id, String vendorId, Map<String, dynamic> map) {
    // Support both old bool inStock and new int quantity.
    int qty;
    if (map['quantity'] != null) {
      qty = (map['quantity'] as num).toInt();
    } else if (map['inStock'] == true) {
      qty = 1; // treat old "in stock" as quantity=1
    } else {
      qty = 0;
    }
    return Product(
      id: id,
      vendorId: vendorId,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      quantity: qty,
      sku: map['sku'],
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'quantity': quantity,
        'sku': sku,
        'lowStockThreshold': lowStockThreshold,
      };

  Product copyWith({
    String? name,
    double? price,
    String? imageUrl,
    String? category,
    int? quantity,
    String? sku,
    int? lowStockThreshold,
  }) =>
      Product(
        id: id,
        vendorId: vendorId,
        name: name ?? this.name,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        sku: sku ?? this.sku,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      );
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get subtotal => product.price * quantity;
}

class KgoroOrder {
  final String id;
  final String customerId;
  final ServiceType type;
  final String? vendorId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String dropoffArea;
  final double dropoffLat;
  final double dropoffLng;
  final String? driverId;
  final OrderStatus status;
  final DateTime createdAt;

  KgoroOrder({
    required this.id,
    required this.customerId,
    required this.type,
    this.vendorId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.dropoffArea,
    required this.dropoffLat,
    required this.dropoffLng,
    this.driverId,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });

  factory KgoroOrder.fromMap(String id, Map<String, dynamic> map) => KgoroOrder(
        id: id,
        customerId: map['customerId'] ?? '',
        type: ServiceType.values[map['type'] ?? 0],
        vendorId: map['vendorId'],
        items: List<Map<String, dynamic>>.from(map['items'] ?? []),
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        dropoffArea: map['dropoffArea'] ?? '',
        dropoffLat: (map['dropoffLat'] as num?)?.toDouble() ?? 0,
        dropoffLng: (map['dropoffLng'] as num?)?.toDouble() ?? 0,
        driverId: map['driverId'],
        status: OrderStatus.values[map['status'] ?? 0],
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class RideRequest {
  final String id;
  final String customerId;
  final double pickupLat;
  final double pickupLng;
  final String pickupArea;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffArea;
  final double estimatedFare;
  final String? driverId;
  final OrderStatus status;
  final DateTime createdAt;

  RideRequest({
    required this.id,
    required this.customerId,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupArea,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffArea,
    required this.estimatedFare,
    this.driverId,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });

  factory RideRequest.fromMap(String id, Map<String, dynamic> map) => RideRequest(
        id: id,
        customerId: map['customerId'] ?? '',
        pickupLat: (map['pickupLat'] as num?)?.toDouble() ?? 0,
        pickupLng: (map['pickupLng'] as num?)?.toDouble() ?? 0,
        pickupArea: map['pickupArea'] ?? '',
        dropoffLat: (map['dropoffLat'] as num?)?.toDouble() ?? 0,
        dropoffLng: (map['dropoffLng'] as num?)?.toDouble() ?? 0,
        dropoffArea: map['dropoffArea'] ?? '',
        estimatedFare: (map['estimatedFare'] as num?)?.toDouble() ?? 0,
        driverId: map['driverId'],
        status: OrderStatus.values[map['status'] ?? 0],
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      );
}
