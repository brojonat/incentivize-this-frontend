import 'package:intl/intl.dart';

class PaidBountyItem {
  final String signature;
  final DateTime timestamp;
  final String recipientOwnerWallet;
  final double amount;
  final String? memo;

  PaidBountyItem({
    required this.signature,
    required this.timestamp,
    required this.recipientOwnerWallet,
    required this.amount,
    this.memo,
  });

  factory PaidBountyItem.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    try {
      // Try parsing ISO 8601 format first (common standard)
      timestamp = DateTime.parse(json['timestamp'] as String);
    } catch (e) {
      // Fallback or default if parsing fails
      print('Error parsing timestamp: ${json['timestamp']}, error: $e');
      timestamp = DateTime(1970); // Default to epoch or handle differently
    }

    return PaidBountyItem(
      signature: json['signature'] as String? ?? '',
      timestamp: timestamp,
      recipientOwnerWallet: json['recipient_owner_wallet'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      memo: json['memo'] as String?,
    );
  }

  // Helper for formatted timestamp
  String get formattedTimestamp {
    // Example: Aug 15, 2024 10:30 AM
    return DateFormat('MMM d, yyyy h:mm a').format(timestamp.toLocal());
  }

  // Helper for formatted amount
  String get formattedAmount {
    // Example: $123.45
    final formatCurrency = NumberFormat.simpleCurrency(decimalDigits: 2);
    return formatCurrency.format(amount);
  }
}
