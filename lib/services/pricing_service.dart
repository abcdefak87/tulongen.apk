import '../models/help_request.dart';

/// Service untuk kalkulasi ongkos berbasis jarak
/// Formula: ONGKOS = Base Fee + (Jarak × Rate per KM)
/// 
/// Pricing lebih murah dari ojol karena ini community-based tolong-menolong
/// Referensi: Gojek/Grab ~Rp 2.000-2.600/km, TULONGEN ~50-60% dari itu
class PricingService {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  // Base fee (biaya dasar)
  static const double baseFee = 5000;
  
  // Rate per kilometer
  static const double ratePerKm = 1500;
  
  // Biaya tambahan untuk barang berat
  static const double heavyItemFee = 5000;
  
  // Jarak maksimum sebelum nego manual
  static const double maxAutoDistance = 20;

  /// Kategori yang tidak perlu ongkos jarak (aktivitas sosial)
  static const List<HelpCategory> freeDistanceCategories = [
    HelpCategory.gaming,
    HelpCategory.hangout,
    HelpCategory.study,
  ];

  /// Hitung estimasi ongkos berdasarkan jarak
  PriceEstimate calculatePrice({
    required double distanceKm,
    required HelpCategory category,
    bool isHeavyItem = false,
  }) {
    // Kategori sosial = gratis (tidak ada ongkos jarak)
    if (freeDistanceCategories.contains(category)) {
      return PriceEstimate(
        minPrice: 0,
        maxPrice: 0,
        distanceKm: distanceKm,
        isFreeCategory: true,
        message: 'Kategori ini biasanya gratis atau seikhlasnya',
      );
    }

    // Jarak terlalu jauh = nego manual
    if (distanceKm > maxAutoDistance) {
      final basePrice = baseFee + (maxAutoDistance * ratePerKm);
      return PriceEstimate(
        minPrice: basePrice,
        maxPrice: null, // Nego
        distanceKm: distanceKm,
        isNegotiable: true,
        message: 'Jarak jauh, sebaiknya nego langsung 💬',
      );
    }

    // Kalkulasi normal
    double basePrice = baseFee + (distanceKm * ratePerKm);
    
    // Tambahan untuk barang berat
    if (isHeavyItem) {
      basePrice += heavyItemFee;
    }

    // Range harga (±20% untuk fleksibilitas)
    final minPrice = (basePrice * 0.8).roundToDouble();
    final maxPrice = (basePrice * 1.2).roundToDouble();

    return PriceEstimate(
      minPrice: _roundToThousand(minPrice),
      maxPrice: _roundToThousand(maxPrice),
      distanceKm: distanceKm,
      suggestedPrice: _roundToThousand(basePrice),
      message: _getPriceMessage(distanceKm),
    );
  }

  /// Dapatkan tabel harga untuk referensi
  List<PriceRange> getPriceTable() {
    return [
      PriceRange(minKm: 0, maxKm: 1, minPrice: 5000, maxPrice: 7000, label: 'Dekat banget'),
      PriceRange(minKm: 1, maxKm: 3, minPrice: 7000, maxPrice: 10000, label: 'Lumayan dekat'),
      PriceRange(minKm: 3, maxKm: 5, minPrice: 10000, maxPrice: 13000, label: 'Sedang'),
      PriceRange(minKm: 5, maxKm: 10, minPrice: 13000, maxPrice: 20000, label: 'Agak jauh'),
      PriceRange(minKm: 10, maxKm: 15, minPrice: 20000, maxPrice: 28000, label: 'Jauh'),
      PriceRange(minKm: 15, maxKm: 20, minPrice: 28000, maxPrice: 35000, label: 'Jauh banget'),
      PriceRange(minKm: 20, maxKm: double.infinity, minPrice: 35000, maxPrice: null, label: 'Nego aja'),
    ];
  }

  /// Dapatkan range harga berdasarkan jarak
  PriceRange? getPriceRangeForDistance(double distanceKm) {
    final table = getPriceTable();
    for (final range in table) {
      if (distanceKm >= range.minKm && distanceKm < range.maxKm) {
        return range;
      }
    }
    return table.last;
  }

  /// Format harga ke Rupiah
  String formatPrice(double price) {
    if (price >= 1000000) {
      return 'Rp ${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)} jt';
    } else if (price >= 1000) {
      final thousands = price / 1000;
      if (thousands == thousands.roundToDouble()) {
        return 'Rp ${thousands.toInt()}rb';
      }
      return 'Rp ${thousands.toStringAsFixed(1)}rb';
    }
    return 'Rp ${price.toInt()}';
  }

  /// Format range harga
  String formatPriceRange(double? minPrice, double? maxPrice) {
    if (minPrice == null && maxPrice == null) return 'Nego';
    if (minPrice == 0 && maxPrice == 0) return 'Gratis';
    if (maxPrice == null) return '${formatPrice(minPrice!)}+';
    if (minPrice == maxPrice) return formatPrice(minPrice!);
    return '${formatPrice(minPrice!)} - ${formatPrice(maxPrice)}';
  }

  /// Bulatkan ke ribuan terdekat
  double _roundToThousand(double price) {
    return (price / 1000).round() * 1000;
  }

  /// Pesan berdasarkan jarak
  String _getPriceMessage(double distanceKm) {
    if (distanceKm < 1) return 'Deket banget nih! 🚶';
    if (distanceKm < 3) return 'Masih deket, santai 🛵';
    if (distanceKm < 5) return 'Jarak sedang 🏍️';
    if (distanceKm < 10) return 'Lumayan jauh nih 🚗';
    if (distanceKm < 15) return 'Agak jauh, worth it? 🤔';
    if (distanceKm < 20) return 'Jauh juga ya 😅';
    return 'Jauh banget, mending nego 💬';
  }
}

/// Model untuk estimasi harga
class PriceEstimate {
  final double minPrice;
  final double? maxPrice;
  final double? suggestedPrice;
  final double distanceKm;
  final bool isFreeCategory;
  final bool isNegotiable;
  final String message;

  PriceEstimate({
    required this.minPrice,
    this.maxPrice,
    this.suggestedPrice,
    required this.distanceKm,
    this.isFreeCategory = false,
    this.isNegotiable = false,
    required this.message,
  });

  String get displayRange {
    final service = PricingService();
    if (isFreeCategory) return 'Gratis / Seikhlasnya';
    if (isNegotiable) return '${service.formatPrice(minPrice)}+ (Nego)';
    return service.formatPriceRange(minPrice, maxPrice);
  }
}

/// Model untuk tabel range harga
class PriceRange {
  final double minKm;
  final double maxKm;
  final double minPrice;
  final double? maxPrice;
  final String label;

  PriceRange({
    required this.minKm,
    required this.maxKm,
    required this.minPrice,
    this.maxPrice,
    required this.label,
  });

  String get distanceLabel {
    if (maxKm == double.infinity) return '>${minKm.toInt()} km';
    if (minKm == 0) return '<${maxKm.toInt()} km';
    return '${minKm.toInt()}-${maxKm.toInt()} km';
  }

  String get priceLabel {
    final service = PricingService();
    return service.formatPriceRange(minPrice, maxPrice);
  }
}
