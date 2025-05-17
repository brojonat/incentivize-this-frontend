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

    // Robust amount parsing
    double amountValue = 0.0;
    final dynamic amountData = json['amount'];
    if (amountData is num) {
      amountValue = amountData.toDouble();
    } else if (amountData is Map<String, dynamic>) {
      // It's a complex object (e.g., solana.USDCAmount from PayoutDetail struct).
      // As per requirements, we are not displaying this amount on the detail page
      // when fetched for a specific workflow, so we can default it or extract
      // a 'value' field if it existed and was needed.
      // For now, defaulting to 0.0 is fine as it won't be shown in this context.
      // If this model were exclusively for PayoutDetail, we might parse its sub-fields.
    }

    return PaidBountyItem(
      signature:
          json['signature'] as String? ?? '', // Default to empty if not present
      timestamp: timestamp,
      // PayoutDetail sends 'payout_wallet', allow it to be parsed here if available,
      // otherwise default to empty. User mentioned it's intentionally "".
      recipientOwnerWallet: json['payout_wallet'] as String? ??
          json['recipient_owner_wallet'] as String? ??
          '',
      amount: amountValue,
      memo: json['memo'] as String?, // Default to null if not present
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
