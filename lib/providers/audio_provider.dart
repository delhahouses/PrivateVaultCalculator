import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/vault_file.dart';
import 'vault_provider.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<VaultFile> _playlist = [];
  int _currentIndex = -1;
  
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _playbackSpeed = 1.0;
  
  // Track visualizer mock values for equalizer UI
  final List<double> _visualizerBars = List.generate(10, (_) => 0.1);

  List<VaultFile> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  double get playbackSpeed => _playbackSpeed;
  List<double> get visualizerBars => _visualizerBars;

  VaultFile? get currentTrack => 
      (_currentIndex >= 0 && _currentIndex < _playlist.length) ? _playlist[_currentIndex] : null;

  AudioProvider() {
    _initStreams();
  }

  void _initStreams() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      _position = pos;
      _updateVisualizer();
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isRepeat) {
        seek(Duration.zero);
        resume();
      } else {
        next();
      }
    });
  }

  void _updateVisualizer() {
    if (_playerState == PlayerState.playing) {
      // Mock visualizer movements
      for (int i = 0; i < _visualizerBars.length; i++) {
        _visualizerBars[i] = 0.1 + (0.9 * (i % 2 == 0 ? (_position.inMilliseconds % 500) / 500 : (500 - (_position.inMilliseconds % 500)) / 500));
      }
    } else {
      _visualizerBars.fillRange(0, _visualizerBars.length, 0.1);
    }
  }

  /// Sets the active playlist and starts playing the track at the specified index.
  Future<void> playPlaylist(List<VaultFile> tracks, int startIndex, VaultProvider vaultProvider) async {
    _playlist = List.from(tracks);
    _currentIndex = startIndex;
    if (_playlist.isNotEmpty) {
      await _playCurrent(vaultProvider);
    }
  }

  Future<void> _playCurrent(VaultProvider vaultProvider) async {
    if (currentTrack == null) return;
    
    try {
      await _audioPlayer.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      
      // Decrypt file to a temporary location for playback
      final decryptedFile = await vaultProvider.getDecryptedFile(currentTrack!);
      
      // Play device file source
      await _audioPlayer.play(DeviceFileSource(decryptedFile.path));
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      notifyListeners();
    } catch (e) {
      // Handle playback error
    }
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _playlist = [];
    _currentIndex = -1;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    
    if (_isShuffle) {
      // Pick random index
      _currentIndex = (DateTime.now().millisecondsSinceEpoch) % _playlist.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    notifyListeners();
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setPlaybackRate(speed);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
