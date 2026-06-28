import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../models/vault_file.dart';
import '../../../providers/vault_provider.dart';

class VideoViewerPage extends StatefulWidget {
  final VaultFile file;

  const VideoViewerPage({super.key, required this.file});

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  File? _tempDecryptedFile;
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _decryptAndInit();
  }

  Future<void> _decryptAndInit() async {
    try {
      final vaultProv = Provider.of<VaultProvider>(context, listen: false);
      final file = await vaultProv.getDecryptedFile(widget.file);
      _tempDecryptedFile = file;

      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {
            _isLoading = false;
            _controller!.play();
          });
        });

      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    
    // Crucial for security: delete decrypted file immediately
    if (_tempDecryptedFile != null) {
      _tempDecryptedFile!.exists().then((exists) {
        if (exists) {
          _tempDecryptedFile!.delete().catchError((_) => _tempDecryptedFile!);
        }
      });
    }
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    HapticFeedback.lightImpact();
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller?.value;
    final isPlaying = value?.isPlaying ?? false;
    final position = value?.position ?? Duration.zero;
    final duration = value?.duration ?? Duration.zero;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : (_errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontFamily: 'Outfit'),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: value!.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                      // Controls Overlay
                      if (_showControls) ...[
                        Positioned.fill(
                          child: Container(
                            color: Colors.black38,
                          ),
                        ),
                        // Top bar
                        Positioned(
                          top: 40,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Text(
                                  widget.file.originalName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Outfit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Center Play Button
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 72,
                          ),
                          onPressed: _togglePlay,
                        ),
                        // Bottom Progress and Time
                        Positioned(
                          bottom: 30,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: Theme.of(context).colorScheme.primary,
                                  bufferedColor: Colors.white24,
                                  backgroundColor: Colors.white10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                )),
    );
  }
}
