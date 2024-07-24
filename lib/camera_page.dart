import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyAppss());
}

class MyAppss extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pothole Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late bool _isLoading;
  late bool _isRecording;
  late bool _isUploading;
  late CameraController _cameraController;
  late LocationData _locationData;
  late List<List<dynamic>> _locationList;
  late Timer _locationTimer;
  late int _currentSecond;
  late VideoPlayerController _videoPlayerController;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _isRecording = false;
    _isUploading = false;
    _currentSecond = 0;
    _locationList = [];
    _initState();
  }

  Future<void> _initState() async {
    await _requestPermissions();
    _initCamera();
    _initLocation();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _locationTimer.cancel();
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await permission_handler.Permission.camera.request();
    await permission_handler.Permission.microphone.request();
  }

  _initCamera() async {
    final cameras = await availableCameras();
    final rear = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _cameraController = CameraController(rear, ResolutionPreset.high);

    await _cameraController.initialize();
    setState(() => _isLoading = false);
  }

  _initLocation() async {
    final location = Location();
    _locationData = await location.getLocation();
    _startLocationTimer();
  }

  _startLocationTimer() async {
    _locationTimer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      _captureLocation();
    });
  }

  _captureLocation() async {
    _locationData = await Location().getLocation();
    final latitude = _locationData.latitude ?? 0.0;
    final longitude = _locationData.longitude ?? 0.0;

    _locationList.add([_currentSecond, latitude, longitude]);
    _currentSecond++;
  }

  _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() => _isRecording = false);
      _locationTimer.cancel();

      final csvData = _convertToCsv(_locationList);
      final csvFile = await _createTempFile('csv');
      await csvFile.writeAsString(csvData);

      _showPreview(file.path, csvFile.path);
    } else {
      _startLocationTimer();
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  String _convertToCsv(List<List<dynamic>> data) {
    final List<String> csvRows = [];
    csvRows.add('Timestamp,Latitude,Longitude');
    for (final row in data) {
      csvRows.add(row.join(','));
    }
    return csvRows.join('\n');
  }

  Future<File> _createTempFile(String extension) async {
    final directory = await getTemporaryDirectory();
    return File(
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.$extension');
  }

  _showPreview(String videoFilePath, String csvFilePath) async {
    _videoPlayerController = VideoPlayerController.file(File(videoFilePath))
      ..initialize().then((_) {
        setState(() {});
      });

    setState(() => _statusMessage = 'Preview');

    // Show preview with status
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$_statusMessage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  await _uploadToAWS(videoFilePath, csvFilePath);
                },
                child: Text(_isUploading ? 'Uploading...' : 'Upload'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadToAWS(String videoFilePath, String csvFilePath) async {
    setState(() => _isUploading = true);
    try {
      final videoFile = File(videoFilePath);
      final csvFile = File(csvFilePath);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://ec2-34-239-144-44.compute-1.amazonaws.com:8080/predict'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: 'video.mp4',
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'csv_file',
          csvFile.path,
          filename: 'location.csv',
        ),
      );

      setState(() => _statusMessage = 'Uploading');

      var response = await request.send();
      if (response.statusCode == 200) {
        setState(() => _statusMessage = 'Upload Successful');
        var responseData = await http.Response.fromStream(response);
        if (responseData.body.isNotEmpty) {
          setState(
              () => _statusMessage = 'Process Finished: ${responseData.body}');
        }
      } else {
        setState(
            () => _statusMessage = 'Upload Failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Upload Error: $e');
      print('Error uploading video and location data: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return FutureBuilder<permission_handler.PermissionStatus>(
        future: Future.value(permission_handler.Permission.camera.status),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == permission_handler.PermissionStatus.granted) {
              return Scaffold(
                body: Stack(
                  children: [
                    SizedBox.expand(
                      child: CameraPreview(_cameraController),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: FloatingActionButton(
                          backgroundColor: Colors.red,
                          child: Icon(_isRecording ? Icons.stop : Icons.circle),
                          onPressed: () => _recordVideo(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      left: 20,
                      child: Text(
                        _statusMessage,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Text('Camera permission denied'),
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );
    }
  }
}
