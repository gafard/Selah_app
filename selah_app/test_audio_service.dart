import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/services/audio_player_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Service Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AudioTestPage(),
    );
  }
}

class AudioTestPage extends StatefulWidget {
  @override
  _AudioTestPageState createState() => _AudioTestPageState();
}

class _AudioTestPageState extends State<AudioTestPage> {
  late AudioPlayerService _audio;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _audio = AudioPlayerService();
    _initAudio();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    try {
      // Test with a sample audio URL (replace with your actual URL)
      await _audio.init(url: Uri.parse('https://www.soundjay.com/misc/sounds/bell-ringing-05.wav'));
      _audio.position$.listen((d) => setState(() => _pos = d));
      _audio.duration$.listen((d) => setState(() => _dur = d ?? Duration.zero));
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Audio initialization failed: $e');
    }
  }

  void _toggleAudio() async {
    try {
      if (_audio.isPlaying) {
        await _audio.pause();
      } else {
        await _audio.play();
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio error: $e')),
      );
    }
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dur.inMilliseconds == 0
        ? 0.0
        : _pos.inMilliseconds / _dur.inMilliseconds;

    return Scaffold(
      appBar: AppBar(title: Text('Audio Service Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Audio Service Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Status: ${_isInitialized ? "Initialized" : "Not initialized"}'),
            SizedBox(height: 20),
            if (_isInitialized) ...[
              Text('Position: ${_fmt(_pos)}'),
              Text('Duration: ${_fmt(_dur)}'),
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleAudio,
                child: Text(_audio.isPlaying ? 'Pause' : 'Play'),
              ),
            ] else
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
