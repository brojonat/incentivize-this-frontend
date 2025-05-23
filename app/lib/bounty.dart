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

  bool get isClaimable {
    return !(rawStatus == 'Refunded' || rawStatus == 'Cancelled');
  }

  factory Bounty.fromJson(Map<String, dynamic> json) {
    final List<dynamic> requirementsRaw = json['requirements'] ?? [];
    final List<String> requirements =
        requirementsRaw.whereType<String>().map((req) => req).toList();

    final String platform =
        json['platform_kind']?.toString().toUpperCase() ?? 'Unknown Platform';
    final String defaultTitle = '$platform Bounty';

    String title = defaultTitle;
    if (requirements.isNotEmpty) {
      final firstRequirement = requirements.first;
      final sentences = firstRequirement.split(RegExp(r'[.!?]'));
      if (sentences.isNotEmpty) {
        final firstSentence = sentences.first.trim();
        if (firstSentence.isNotEmpty) {
          title = firstSentence;
        }
      }
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
    if (json['end_time'] is String && json['end_time'].isNotEmpty) {
      deadline = DateTime.tryParse(json['end_time']);
    }

    final String contentKind = json['content_kind']?.toString() ?? 'Unknown';
    final String rawStatus = json['status']?.toString() ?? 'Unknown';

    return Bounty(
      id: json['workflow_id'] ?? '',
      title: title,
      description: description,
      bountyPerPost: bountyPerPost,
      deadline: deadline,
      platformKind: platform,
      totalBounty: totalBounty,
      remainingBountyValue: remainingBountyValue,
      contentKind: contentKind,
      rawStatus: rawStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workflow_id': id,
      'title': title,
      'description': description,
      'bounty_per_post': bountyPerPost,
      'total_bounty': totalBounty,
      'remaining_bounty_value': remainingBountyValue,
      'end_time': deadline?.toIso8601String(),
      'status': rawStatus,
      'platform_kind': platformKind,
      'content_kind': contentKind,
    };
  }
}
