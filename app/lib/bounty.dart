import 'package:flutter/material.dart';

class StatusInfo {
  final String text;
  final IconData icon;
  final Color textColor;
  final Color backgroundColor;

  StatusInfo({
    required this.text,
    required this.icon,
    required this.textColor,
    required this.backgroundColor,
  });
}

class TierInfo {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  TierInfo({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}

class Bounty {
  final String id;
  final String title;
  final String description;
  final double bountyPerPost;
  final DateTime? deadline;
  final String platformKind;
  final double totalBounty;
  final double remainingBountyValue;
  final String contentKind;
  final String rawStatus;
  final int tier;
  final double? totalCharged;
  final DateTime? paymentTimeoutExpiresAt;

  Bounty({
    required this.id,
    required this.title,
    required this.description,
    required this.bountyPerPost,
    this.deadline,
    required this.platformKind,
    required this.totalBounty,
    required this.remainingBountyValue,
    required this.contentKind,
    required this.rawStatus,
    required this.tier,
    this.totalCharged,
    this.paymentTimeoutExpiresAt,
  });

  String get displayStatus {
    switch (rawStatus) {
      case 'AwaitingFunding':
        return 'Awaiting Funding';
      case 'TransferringFee':
        return 'Transferring Fee';
      case 'Listening':
        return 'Listening';
      case 'Paying':
        return 'Paying';
      case 'Refunded':
        return 'Refunded';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return rawStatus;
    }
  }

  int get totalPosts {
    if (bountyPerPost <= 0) return 0;
    return (totalBounty / bountyPerPost).round();
  }

  int get remainingPosts {
    if (bountyPerPost <= 0) return 0;
    return (remainingBountyValue / bountyPerPost).round();
  }

  String get remainingPostsDisplay {
    if (totalPosts <= 0) {
      return 'N/A Remaining';
    }
    return '$remainingPosts out of $totalPosts remain';
  }

  bool get isActive {
    // An active bounty is one that has not been cancelled or refunded.
    return rawStatus != 'Refunded' && rawStatus != 'Cancelled';
  }

  bool get isClaimable {
    // A bounty is only claimable when it's actively listening for submissions.
    return rawStatus == 'Listening';
  }

  IconData get platformIcon {
    switch (platformKind.toUpperCase()) {
      case 'REDDIT':
        return Icons.reddit;
      case 'YOUTUBE':
        return Icons.play_arrow;
      case 'TWITCH':
        return Icons.tv;
      case 'TRIPADVISOR':
        return Icons.travel_explore;
      case 'HACKERNEWS':
        return Icons.code;
      case 'INSTAGRAM':
        return Icons.camera_alt;
      case 'BLUESKY':
        return Icons.cloud;
      case 'STEAM':
        return Icons.sports_esports;
      default:
        return Icons.device_hub;
    }
  }

  int? get daysRemaining {
    if (deadline == null) {
      return null;
    }
    // Use DateUtils.dateOnly to compare dates without the time component for a
    // more accurate "days left" calculation.
    final today = DateUtils.dateOnly(DateTime.now());
    final deadlineDate = DateUtils.dateOnly(deadline!);
    return deadlineDate.difference(today).inDays;
  }

  StatusInfo getStatusInfo(ThemeData theme) {
    final days = daysRemaining;

    // First, check for deadline-related statuses if the bounty is claimable
    if (days != null && isClaimable) {
      final Color textColor;
      final String text;
      final IconData icon;

      if (days < 0) {
        text = 'Ended';
        icon = Icons.hourglass_disabled_outlined;
        textColor = theme.colorScheme.outline;
      } else if (days == 0) {
        text = 'Ends today';
        icon = Icons.hourglass_bottom_outlined;
        textColor = theme.colorScheme.primary;
      } else if (days == 1) {
        text = '1 day left';
        icon = Icons.hourglass_bottom_outlined;
        textColor = theme.colorScheme.primary;
      } else {
        text = '$days days left';
        icon = Icons.hourglass_bottom_outlined;
        textColor = theme.colorScheme.primary;
      }
      return StatusInfo(
        text: text,
        icon: icon,
        textColor: textColor,
        backgroundColor: textColor.withOpacity(0.1),
      );
    }

    // Fallback to other statuses
    final IconData icon;
    switch (rawStatus) {
      case 'AwaitingFunding':
      case 'TransferringFee':
        icon = Icons.hourglass_top_outlined;
        break;
      case 'Listening':
        icon = Icons.play_circle_outline;
        break;
      case 'Paying':
        icon = Icons.payment_outlined;
        break;
      case 'Refunded':
      case 'Cancelled':
        icon = Icons.stop_circle_outlined;
        break;
      default:
        icon = Icons.pause_circle_outline;
    }

    final Color textColor =
        isActive ? theme.colorScheme.primary : theme.colorScheme.outline;

    return StatusInfo(
      text: displayStatus,
      icon: icon,
      textColor: textColor,
      backgroundColor: textColor.withOpacity(0.1),
    );
  }

  TierInfo tierInfo(ThemeData theme) {
    switch (tier) {
      case 8: // Altruist
        return TierInfo(
          name: 'Altruist',
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
          textColor: const Color(0xFFD81B60), // Toned down pink
          icon: Icons.volunteer_activism,
        );
      case 4: // Premium
        return TierInfo(
          name: 'Premium',
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          textColor: theme.colorScheme.primary,
          icon: Icons.star,
        );
      case 0: // Black Hat
      default:
        return TierInfo(
          name: 'Black Hat',
          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
          textColor: theme.colorScheme.onSurface,
          icon: Icons.security,
        );
    }
  }

  factory Bounty.fromJson(Map<String, dynamic> json) {
    final List<dynamic> requirementsRaw = json['requirements'] ?? [];
    final List<String> requirements =
        requirementsRaw.whereType<String>().map((req) => req).toList();

    final String platform =
        json['platform_kind']?.toString().trim().toUpperCase() ??
            'Unknown Platform';
    final String defaultTitle = '$platform Bounty';

    String title = json['title']?.toString().trim() ?? defaultTitle;
    if (title.isEmpty) {
      title = defaultTitle;
    }

    final String description = requirements.isNotEmpty
        ? requirements.join('\n')
        : 'No specific requirements listed.';

    final double bountyPerPost = (json['bounty_per_post'] is num)
        ? (json['bounty_per_post'] as num).toDouble()
        : 0.0;

    final double totalBounty = (json['total_bounty'] is num)
        ? (json['total_bounty'] as num).toDouble()
        : 0.0;
    final double remainingBountyValue = (json['remaining_bounty_value'] is num)
        ? (json['remaining_bounty_value'] as num).toDouble()
        : 0.0;

    DateTime? deadline;
    if (json['end_at'] is String && (json['end_at'] as String).isNotEmpty) {
      deadline = DateTime.tryParse(json['end_at'] as String);
    }

    final String finalContentKind =
        json['content_kind']?.toString() ?? 'Unknown';
    final String rawStatus = json['status']?.toString() ?? 'Unknown';
    final int tier = (json['tier'] is int) ? json['tier'] : 0;
    final double? totalCharged = (json['total_charged'] is num)
        ? (json['total_charged'] as num).toDouble()
        : null;
    final DateTime? paymentTimeoutExpiresAt =
        json['payment_timeout_expires_at'] is String &&
                (json['payment_timeout_expires_at'] as String).isNotEmpty
            ? DateTime.tryParse(json['payment_timeout_expires_at'] as String)
            : null;

    return Bounty(
      id: json['bounty_id'] ?? '',
      title: title,
      description: description,
      bountyPerPost: bountyPerPost,
      deadline: deadline,
      platformKind: platform,
      totalBounty: totalBounty,
      remainingBountyValue: remainingBountyValue,
      contentKind: finalContentKind,
      rawStatus: rawStatus,
      tier: tier,
      totalCharged: totalCharged,
      paymentTimeoutExpiresAt: paymentTimeoutExpiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bounty_id': id,
      'title': title,
      'description': description,
      'bounty_per_post': bountyPerPost,
      'total_bounty': totalBounty,
      'remaining_bounty_value': remainingBountyValue,
      'end_at': deadline?.toIso8601String(),
      'status': rawStatus,
      'platform_kind': platformKind,
      'content_kind': contentKind,
      'tier': tier,
      'total_charged': totalCharged,
      'payment_timeout_expires_at': paymentTimeoutExpiresAt?.toIso8601String(),
    };
  }
}
