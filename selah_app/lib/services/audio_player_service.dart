import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioPlayerService {
  final _player = AudioPlayer();
  
  Future<void> init({required Uri url}) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await _player.setAudioSource(AudioSource.uri(url));
  }
  
  Stream<Duration> get position$ => _player.positionStream;
  Stream<Duration?> get duration$ => _player.durationStream;
  Stream<PlayerState> get state$ => _player.playerStateStream;
  
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration d) => _player.seek(d);
  Future<void> dispose() => _player.dispose();
  
  // Get current position synchronously
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  PlayerState get state => _player.playerState;
  
  // Check if currently playing
  bool get isPlaying => _player.playing;
}
