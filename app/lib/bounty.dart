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
      String candidateTitle = defaultTitle;

      for (final reqContent in requirements) {
        String currentReqTrimmed = reqContent.trim();
        if (currentReqTrimmed.isEmpty) continue;

        final sentences = currentReqTrimmed.split(RegExp(r'[.!?]'));
        String firstSentence =
            sentences.isNotEmpty ? sentences.first.trim() : currentReqTrimmed;

        if (firstSentence.isEmpty) continue;

        bool currentSentenceIsGenericOrTooShort = false;
        String lowerSentence = firstSentence.toLowerCase();
        String lowerPlatform = platform.toLowerCase();

        if (firstSentence.length < 20 || firstSentence.split(' ').length < 3) {
          currentSentenceIsGenericOrTooShort = true;
        } else {
          List<String> contentTypes = [
            'post',
            'comment',
            'video',
            'tweet',
            'article',
            'link',
            'story',
            'thread',
            'bounty',
            'task',
            'submission',
            'content',
            'item',
            'message'
          ];
          List<String> prefixes = [
            "",
            "a ",
            "an ",
            "the ",
            "my ",
            "this is ",
            "this is a ",
            "this is an ",
            "create ",
            "create a ",
            "create an ",
            "make ",
            "make a ",
            "make an ",
            "submit ",
            "submit a ",
            "submit an ",
            "write ",
            "write a ",
            "write an ",
            "share ",
            "share a ",
            "share an ",
            "looking for ",
            "seeking "
          ];

          for (String type in contentTypes) {
            String term = '$lowerPlatform $type';
            for (String prefix in prefixes) {
              if (lowerSentence == '$prefix$term') {
                currentSentenceIsGenericOrTooShort = true;
                break;
              }
            }
            if (currentSentenceIsGenericOrTooShort) break;
          }
        }

        if (!currentSentenceIsGenericOrTooShort) {
          candidateTitle = firstSentence;
          break;
        }
      }
      title = candidateTitle;
    }

    const int maxTitleLength = 80;
    if (title.length > maxTitleLength) {
      title = '${title.substring(0, maxTitleLength - 3)}...';
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
      id: json['bounty_id'] ?? '',
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
      'bounty_id': id,
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
