import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CluesoVideoPlayer extends StatelessWidget {
  final String videoId;

  const CluesoVideoPlayer({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final Uri videoUri =
        Uri.parse('https://finicky-elephant.clueso.site/embed/$videoId');

    final controller = WebViewController()..loadRequest(videoUri);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: controller),
    );
  }
}
