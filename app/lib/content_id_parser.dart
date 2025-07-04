import 'package:flutter/foundation.dart'; // For kDebugMode

class ContentIdParser {
  /// Attempts to parse a content ID from a given input string (which might be a URL).
  ///
  /// Takes the raw [input] from the user and the [platformKind] (e.g., 'REDDIT', 'YOUTUBE', 'TWITCH').
  /// Returns the extracted ID if successful, otherwise returns the original [input].
  static String parse(String input, String platformKind) {
    final trimmedInput = input.trim();
    Uri? uri;

    try {
      // Check if it's a plausible URI before fully parsing
      if (trimmedInput.contains('://') || trimmedInput.startsWith('www.')) {
        uri = Uri.parse(
          // Ensure scheme is present for Uri.parse
          trimmedInput.startsWith('http')
              ? trimmedInput
              : 'https://$trimmedInput',
        );
      }
    } catch (e) {
      // If parsing fails, it's likely not a valid URL, treat as raw ID
      if (kDebugMode) {
        print('Failed to parse URI: $trimmedInput, Error: $e');
      }
      return trimmedInput;
    }

    // If not parsed as a URI, assume it's a raw ID
    if (uri == null) {
      return trimmedInput;
    }

    // Normalize platform type for comparison
    final platform = platformKind.toUpperCase();

    try {
      switch (platform) {
        case 'REDDIT':
          // Regex to capture the last ID segment (post or comment)
          // Example: /r/sub/comments/{post_id}/title/{comment_id}/ -> comment_id
          // Example: /r/sub/comments/{post_id}/title/ -> post_id
          final redditRegex =
              RegExp(r'\/comments\/([^\/]+)(?:\/[^\/]+\/([^\/]+))?');
          final match = redditRegex.firstMatch(uri.path);
          if (match != null) {
            // Prioritize comment_id (group 2) if present, otherwise post_id (group 1)
            final potentialId = match.group(2) ?? match.group(1);
            if (potentialId != null && potentialId.isNotEmpty) {
              return potentialId;
            }
          }
          break;

        case 'YOUTUBE':
          // Check host and look for 'v' query parameter
          if ((uri.host.contains('youtube.com') ||
              uri.host.contains('youtu.be'))) {
            if (uri.queryParameters.containsKey('v')) {
              final videoId = uri.queryParameters['v'];
              if (videoId != null && videoId.isNotEmpty) {
                return videoId;
              }
            }
            // Handle youtu.be short links
            if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
              return uri.pathSegments.first;
            }
          }
          break;

        case 'TWITCH':
          // Check for /clips/{id} or /videos/{id}
          if (uri.host.contains('twitch.tv')) {
            final segments = uri.pathSegments;
            if (segments.length >= 2) {
              if (segments[0] == 'clips' || segments[0] == 'videos') {
                final twitchId = segments[1];
                // Basic validation: Twitch IDs are typically numeric for videos, alphanumeric for clips
                // This isn't exhaustive but prevents grabbing unintended path parts.
                if (twitchId.isNotEmpty &&
                    RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(twitchId)) {
                  return twitchId;
                }
              }
              // Check for clips.twitch.tv/{id} format
              else if (segments.isNotEmpty && uri.host == 'clips.twitch.tv') {
                final clipId = segments[0];
                if (clipId.isNotEmpty &&
                    RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clipId)) {
                  return clipId;
                }
              }
            }
          }
          break;

        case 'TRIPADVISOR':
          if (uri.host.contains('tripadvisor.com')) {
            // Extracts locationID and reviewID from URLs like:
            // ...-d(locationID)-...-r(reviewID)-...
            final tripadvisorRegex = RegExp(r'-d(\d+)-r(\d+)');
            final match = tripadvisorRegex.firstMatch(uri.path);
            if (match != null && match.groupCount == 2) {
              final locationId = match.group(1);
              final reviewId = match.group(2);
              if (locationId != null &&
                  locationId.isNotEmpty &&
                  reviewId != null &&
                  reviewId.isNotEmpty) {
                return '$locationId:$reviewId';
              }
            }
          }
          break;

        case 'HACKERNEWS': // New case for Hacker News
          if (uri.host.contains('news.ycombinator.com') &&
              uri.pathSegments.isNotEmpty &&
              uri.pathSegments.first == 'item' &&
              uri.queryParameters.containsKey('id')) {
            final hnId = uri.queryParameters['id'];
            if (hnId != null && hnId.isNotEmpty) {
              return hnId;
            }
          }
          break;

        case 'INSTAGRAM': // New case for Instagram
          if (uri.host.contains('instagram.com') &&
              uri.pathSegments.isNotEmpty) {
            final segments = uri.pathSegments;
            if (segments.length >= 2 && segments[0] == 'p') {
              final postId = segments[1];
              if (postId.isNotEmpty) {
                return postId;
              }
            }
            // Handle /reel/{id} links as well, as they are common
            if (segments.length >= 2 && segments[0] == 'reel') {
              final reelId = segments[1];
              if (reelId.isNotEmpty) {
                return reelId;
              }
            }
          }
          break;

        case 'BLUESKY': // Updated case for Bluesky
          if (uri.host.contains('bsky.app')) {
            return trimmedInput; // Return the full URI if it's a bsky.app link
          }
          // If platform is BLUESKY but not a bsky.app link,
          // it will fall through to the default behavior (return trimmedInput).
          break;

        default:
          // Unknown platform, assume input is the ID
          break;
      }
    } catch (e) {
      // Handle any unexpected errors during platform-specific parsing
      if (kDebugMode) {
        print(
            'Error parsing content ID for $platform: $trimmedInput, Error: $e');
      }
      // Fallback to original input on error
      return trimmedInput;
    }

    // If no specific parsing logic matched or succeeded, return original input
    return trimmedInput;
  }
}
