import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.asset("assets/videos/ibp_splash_screen.mp4")
          ..initialize().then((_) {
            setState(() {});
            _controller?.play();
            _controller?.setLooping(false);
          });

    _controller?.addListener(() {
      if (!mounted || _controller == null || !_controller!.value.isInitialized)
        return;

      final isFinished = !_controller!.value.isPlaying &&
          (_controller!.value.position >= _controller!.value.duration);

      if (isFinished) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: (_controller?.value.isInitialized ?? false)
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          : Container(color: Colors.black),
    );
  }
}
