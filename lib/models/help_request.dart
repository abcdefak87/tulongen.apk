import 'package:flutter/material.dart';

enum HelpCategory {
  emergency,
  daily,
  education,
  health,
  transport,
  coffee,      // Teman Ngopi
  shopping,    // Titip Beli
  gaming,      // Gaming Buddy
  study,       // Study Buddy
  hangout,     // Nongkrong
  other,
}

enum HelpStatus {
  open,
  negotiating,  // Sedang negosiasi
  inProgress,
  completed,
  cancelled,
}

enum PaymentMethod {
  cash,
  transfer,
}

enum PriceType {
  free,         // Gratis
  voluntary,    // Seikhlasnya
  fixed,        // Harga tetap
  negotiable,   // Bisa nego
}

class HelpRequest {
  final String id;
  final String userId;
  final String userName;
  final IconData userAvatar;
  final String title;
  final String description;
  final HelpCategory category;
  final HelpStatus status;
  final DateTime createdAt;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int helpersCount;
  final PriceType priceType;
  final double? budget;
  final List<PaymentMethod> acceptedPayments;
  final List<HelpOffer> offers;

  HelpRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.location,
    this.latitude,
    this.longitude,
    this.helpersCount = 0,
    this.priceType = PriceType.voluntary,
    this.budget,
    this.acceptedPayments = const [PaymentMethod.cash, PaymentMethod.transfer],
    this.offers = const [],
  });

  String get categoryName {
    switch (category) {
      case HelpCategory.emergency:
        return 'Darurat';
      case HelpCategory.daily:
        return 'Sehari-hari';
      case HelpCategory.education:
        return 'Pendidikan';
      case HelpCategory.health:
        return 'Kesehatan';
      case HelpCategory.transport:
        return 'Transportasi';
      case HelpCategory.coffee:
        return 'Ngopi';
      case HelpCategory.shopping:
        return 'Titip Beli';
      case HelpCategory.gaming:
        return 'Gaming';
      case HelpCategory.study:
        return 'Belajar';
      case HelpCategory.hangout:
        return 'Nongkrong';
      case HelpCategory.other:
        return 'Lainnya';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case HelpCategory.emergency:
        return Icons.emergency;
      case HelpCategory.daily:
        return Icons.home_rounded;
      case HelpCategory.education:
        return Icons.school_rounded;
      case HelpCategory.health:
        return Icons.local_hospital_rounded;
      case HelpCategory.transport:
        return Icons.directions_car_rounded;
      case HelpCategory.coffee:
        return Icons.coffee_rounded;
      case HelpCategory.shopping:
        return Icons.shopping_bag_rounded;
      case HelpCategory.gaming:
        return Icons.sports_esports_rounded;
      case HelpCategory.study:
        return Icons.menu_book_rounded;
      case HelpCategory.hangout:
        return Icons.groups_rounded;
      case HelpCategory.other:
        return Icons.lightbulb_rounded;
    }
  }

  String get priceDisplay {
    switch (priceType) {
      case PriceType.free:
        return 'Gratis';
      case PriceType.voluntary:
        return 'Seikhlasnya';
      case PriceType.fixed:
        return budget != null ? 'Rp ${_formatPrice(budget!)}' : 'Seikhlasnya';
      case PriceType.negotiable:
        return budget != null ? 'Rp ${_formatPrice(budget!)} (Nego)' : 'Nego';
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}jt';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}rb';
    }
    return price.toStringAsFixed(0);
  }

  String get paymentMethodsDisplay {
    if (acceptedPayments.contains(PaymentMethod.cash) && 
        acceptedPayments.contains(PaymentMethod.transfer)) {
      return 'Cash / Transfer';
    } else if (acceptedPayments.contains(PaymentMethod.cash)) {
      return 'Cash';
    } else {
      return 'Transfer';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }
}

// Model untuk penawaran dari penolong
class HelpOffer {
  final String id;
  final String orderId;
  final String helperId;
  final String helperName;
  final IconData helperAvatar;
  final double? offeredPrice;
  final PriceType offerType;
  final String? message;
  final PaymentMethod preferredPayment;
  final DateTime createdAt;
  final OfferStatus status;

  HelpOffer({
    required this.id,
    required this.orderId,
    required this.helperId,
    required this.helperName,
    required this.helperAvatar,
    this.offeredPrice,
    this.offerType = PriceType.voluntary,
    this.message,
    this.preferredPayment = PaymentMethod.cash,
    required this.createdAt,
    this.status = OfferStatus.pending,
  });

  String get priceDisplay {
    switch (offerType) {
      case PriceType.free:
        return 'Gratis';
      case PriceType.voluntary:
        return 'Seikhlasnya';
      case PriceType.fixed:
      case PriceType.negotiable:
        return offeredPrice != null ? 'Rp ${_formatPrice(offeredPrice!)}' : 'Seikhlasnya';
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}jt';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}rb';
    }
    return price.toStringAsFixed(0);
  }
}

enum OfferStatus {
  pending,
  accepted,
  rejected,
  withdrawn,
}

// Model untuk chat/negosiasi
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

enum MessageType {
  text,
  offer,       // Penawaran harga
  location,    // Share lokasi
  system,      // Pesan sistem
}
