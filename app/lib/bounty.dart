class Bounty {
  final String id;
  final String title;
  final String description;
  final double bountyPerPost;
  final DateTime? deadline;
  final bool isActive;
  final String platformType;
  final double totalBounty;
  final double remainingBountyValue;
  final String contentKind;

  Bounty({
    required this.id,
    required this.title,
    required this.description,
    required this.bountyPerPost,
    this.deadline,
    this.isActive = true,
    required this.platformType,
    required this.totalBounty,
    required this.remainingBountyValue,
    required this.contentKind,
  });

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

  factory Bounty.fromJson(Map<String, dynamic> json) {
    final List<dynamic> requirementsRaw = json['requirements'] ?? [];
    final List<String> requirements = requirementsRaw
        .where((req) => req is String)
        .map((req) => req as String)
        .toList();

    final String platform =
        json['platform_type']?.toString().toUpperCase() ?? 'Unknown Platform';
    final String defaultTitle = '$platform Bounty';

    // Extract title from the first sentence of the first requirement
    String title = defaultTitle;
    if (requirements.isNotEmpty) {
      final firstRequirement = requirements.first;
      // Split by common sentence endings. Add more if needed.
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

    final bool isActive = json['status'] == 'Running';

    // Assume content_kind is provided, default to 'Unknown' if not
    final String contentKind = json['content_kind']?.toString() ?? 'Unknown';

    return Bounty(
      id: json['workflow_id'] ?? '',
      title: title,
      description: description,
      bountyPerPost: bountyPerPost,
      deadline: deadline,
      isActive: isActive,
      platformType: platform,
      totalBounty: totalBounty,
      remainingBountyValue: remainingBountyValue,
      contentKind: contentKind,
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
      'status': isActive ? 'Running' : 'Closed',
      'platform_type': platformType,
      'content_kind': contentKind,
    };
  }
}
