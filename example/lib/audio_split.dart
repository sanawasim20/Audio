import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class AudioSplit extends StatefulWidget {
  final File file;

  const AudioSplit(this.file, {Key? key}) : super(key: key);
  @override
  State<AudioSplit> createState() => _AudioSplit();
}

class _AudioSplit extends State<AudioSplit> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  void _loadAudio() async {
    setState(() {
      isLoading = true;
    });
    await _trimmer.loadAudio(audioFile: widget.file);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveAudio() async {
    setState(() {
      _progressVisibility = true;
    });

    // Create a new folder for trimmed audios in the application documents directory
    final appDocumentsDirectory = await getApplicationDocumentsDirectory();
    final trimmedAudioDirectory = Directory('${appDocumentsDirectory.path}/trimmed_audio');
    if (!trimmedAudioDirectory.existsSync()) {
      trimmedAudioDirectory.createSync();
    }

    // Get the trimmed audio file name
    final outputFileName = 'trimmed_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

    // Save the trimmed audio using the trimmer
    await _trimmer.saveTrimmedAudio(
      startValue: _startValue,
      endValue: _endValue,
      customOutputPath: '${trimmedAudioDirectory.path}/$outputFileName',
      onSave: (customOutputPath) {
        setState(() {
          _progressVisibility = false;
        });
        debugPrint('Trimmed audio saved to: $customOutputPath');
      },
    );

    setState(() {
      _progressVisibility = false;
    });

    debugPrint('Trimmed audio saved to: ${trimmedAudioDirectory.path}/$outputFileName');
  }



  @override
  void dispose() {
    if (mounted) {
      _trimmer.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Audio Trimmer"),
        ),
        body: isLoading
            ? const CircularProgressIndicator()
            : Center(
          child: Container(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                  _progressVisibility ? null : () => _saveAudio(),
                  child: const Text("SAVE"),
                ),
                /*ElevatedButton(
                  onPressed:
                  _progressVisibility ? null : () => _splitAudio(),
                  child: const Text("SPLIT"),
                ),*/
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 100,
                      maxAudioLength: const Duration(seconds: 0),
                      viewerWidth: MediaQuery.of(context).size.width,
                      durationStyle: DurationStyle.FORMAT_MM_SS,
                      backgroundColor: Theme.of(context).primaryColor,
                      barColor: Colors.white,
                      durationTextStyle: TextStyle(
                          color: Theme.of(context).primaryColor),
                      allowAudioSelection: true,
                      editorProperties: TrimEditorProperties(
                        borderPaintColor: Colors.pinkAccent,
                        circleSize: 10,
                        borderWidth: 4,
                        borderRadius: 5,
                        circlePaintColor: Colors.pink.shade400,

                      ),
                      areaProperties:
                      TrimAreaProperties.edgeBlur(blurEdges: true),
                      onChangeStart: (value) => _startValue = value,
                      onChangeEnd: (value) => _endValue = value,
                      onChangePlaybackState: (value) {
                        if (mounted) {
                          setState(() => _isPlaying = value);
                        }
                      },
                    ),
                  ),
                ),
                TextButton(
                  child: _isPlaying
                      ? Icon(
                    Icons.pause,
                    size: 80.0,
                    color: Theme.of(context).primaryColor,
                  )
                      : Icon(
                    Icons.play_arrow,
                    size: 80.0,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () async {
                    bool playbackState =
                    await _trimmer.audioPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() => _isPlaying = playbackState);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
