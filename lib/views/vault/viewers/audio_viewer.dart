import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/vault_file.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/vault_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/theme.dart';

class AudioViewerPage extends StatefulWidget {
  final VaultFile file;

  const AudioViewerPage({super.key, required this.file});

  @override
  State<AudioViewerPage> createState() => _AudioViewerPageState();
}

class _AudioViewerPageState extends State<AudioViewerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPlayback();
    });
  }

  void _startPlayback() {
    final vaultProv = Provider.of<VaultProvider>(context, listen: false);
    final audioProv = Provider.of<AudioProvider>(context, listen: false);
    
    // Find all audio files in the folder to build a playlist
    final audioTracks = vaultProv.files
        .where((f) => f.parentFolderId == widget.file.parentFolderId && f.category == 'Audio')
        .toList();
        
    final index = audioTracks.indexWhere((f) => f.id == widget.file.id);
    
    audioProv.playPlaylist(
      audioTracks.isNotEmpty ? audioTracks : [widget.file],
      index >= 0 ? index : 0,
      vaultProv,
    );
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProv = Provider.of<AudioProvider>(context);
    final vaultProv = Provider.of<VaultProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final isDark = settingsProv.isDarkMode;
    final theme = Theme.of(context);

    final currentTrack = audioProv.currentTrack ?? widget.file;
    final isPlaying = audioProv.playerState == PlayerState.playing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated vinyl placeholder or equalizer UI
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: AnimatedRotation(
                      turns: isPlaying ? 100 : 0,
                      duration: const Duration(seconds: 1000),
                      child: Icon(
                        Icons.music_note,
                        size: 96,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                
                // Track Titles
                Column(
                  children: [
                    Text(
                      currentTrack.originalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentTrack.readableSize,
                      style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Outfit'),
                    ),
                  ],
                ),

                // Equalizer Visualizer UI (moving bars)
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: audioProv.visualizerBars.map((value) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: 48 * value,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Progress slider & Times
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: audioProv.position.inSeconds.toDouble(),
                        max: audioProv.duration.inSeconds.toDouble() > 0 
                            ? audioProv.duration.inSeconds.toDouble() 
                            : 100,
                        onChanged: (val) {
                          audioProv.seek(Duration(seconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(audioProv.position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(_formatDuration(audioProv.duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Audio Controls (Repeat, Shuffle, Speed, etc)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: audioProv.isShuffle ? theme.colorScheme.primary : Colors.grey,
                      ),
                      onPressed: () {
                        _triggerHaptic();
                        audioProv.toggleShuffle();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed: () {
                        _triggerHaptic();
                        audioProv.previous();
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        _triggerHaptic();
                        if (isPlaying) {
                          audioProv.pause();
                        } else {
                          audioProv.resume();
                        }
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: () {
                        _triggerHaptic();
                        audioProv.next();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.repeat,
                        color: audioProv.isRepeat ? theme.colorScheme.primary : Colors.grey,
                      ),
                      onPressed: () {
                        _triggerHaptic();
                        audioProv.toggleRepeat();
                      },
                    ),
                  ],
                ),

                // Speed adjustor
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.speed, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    DropdownButton<double>(
                      value: audioProv.playbackSpeed,
                      dropdownColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
                      style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white70 : Colors.black.withOpacity(0.70)),
                      underline: const SizedBox.shrink(),
                      items: [0.5, 1.0, 1.25, 1.5, 2.0].map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s}x', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _triggerHaptic();
                          audioProv.setSpeed(val);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
