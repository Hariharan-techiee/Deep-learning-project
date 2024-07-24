import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mini/video_page.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:location/location.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isLoading = true;
  bool _isRecording = false;
  late CameraController _cameraController;
  late LocationData _locationData;
  late List<List<dynamic>> _locationList;
  late Timer _locationTimer;

  @override
  void initState() {
    _initCamera();
    _initLocation();
    _locationList = [];
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _locationTimer.cancel();
    super.dispose();
  }

  _initCamera() async {
    final cameras = await availableCameras();
    final rear = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(rear, ResolutionPreset.max);
    await _cameraController.initialize();
    setState(() => _isLoading = false);
  }

  _initLocation() async {
    final location = Location();
    _locationData = await location.getLocation();

    // Start the timer to capture location every half second
    _locationTimer = Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
      _captureLocation();
    });
  }

  _captureLocation() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final latitude = _locationData.latitude ?? 0.0;
    final longitude = _locationData.longitude ?? 0.0;

    // Add location data to the list
    _locationList.add([timestamp, latitude, longitude]);
  }

  _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() => _isRecording = false);

      // Save location data as CSV
      final csvData = _convertToCsv(_locationList);

      // Upload the video to Firebase Storage in the 'video' subfolder
      try {
        final videoRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('video/${DateTime.now().millisecondsSinceEpoch}.mp4');

        final locationRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('location/${DateTime.now().millisecondsSinceEpoch}.csv');

        await videoRef.putFile(File(file.path));
        await locationRef.putString(csvData);

        final videoDownloadUrl = await videoRef.getDownloadURL();
        final locationDownloadUrl = await locationRef.getDownloadURL();

        // Navigate to the video page with the download URLs
        final route = MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => VideoPage(
            videoFilePath: videoDownloadUrl,
            locationFilePath: locationDownloadUrl,
            filePath: file.path,
          ),
        );

        Navigator.push(context, route);
      } catch (e) {
        print('Error uploading video and location data: $e');
        // Handle the error, show a snackbar or display an error message
        // based on your application's requirements.
      }
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  String _convertToCsv(List<List<dynamic>> data) {
    final List<String> csvRows = [];

    // Add header row
    csvRows.add('Timestamp,Latitude,Longitude');

    // Add data rows
    for (final row in data) {
      csvRows.add(row.join(','));
    }

    return csvRows.join('\n');
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
      return Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CameraPreview(_cameraController),
            Padding(
              padding: const EdgeInsets.all(25),
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                child: Icon(_isRecording ? Icons.stop : Icons.circle),
                onPressed: () => _recordVideo(),
              ),
            ),
          ],
        ),
      );
    }
  }
}






// import 'dart:io';
// import 'dart:async';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:project/video_page.dart';
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// import 'package:location/location.dart';

// class CameraPage extends StatefulWidget {
//   const CameraPage({Key? key}) : super(key: key);

//   @override
//   _CameraPageState createState() => _CameraPageState();
// }

// class _CameraPageState extends State<CameraPage> {
//   bool _isLoading = true;
//   bool _isRecording = false;
//   late CameraController _cameraController;
//   late LocationData _locationData;
//   late List<List<dynamic>> _locationList;
//   late Timer _locationTimer;
//   int _currentSecond = 0;

//   @override
//   void initState() {
//     _initCamera();
//     _initLocation();
//     _locationList = [];
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _cameraController.dispose();
//     _locationTimer.cancel();
//     super.dispose();
//   }

//   _initCamera() async {
//     final cameras = await availableCameras();
//     final rear = cameras.firstWhere(
//       (camera) => camera.lensDirection == CameraLensDirection.back,
//     );

//     // Set the resolution preset to a lower value (e.g., ResolutionPreset.medium)
//     _cameraController = CameraController(rear, ResolutionPreset.medium);

//     await _cameraController.initialize();
//     setState(() => _isLoading = false);
//   }

//   _initLocation() async {
//     final location = Location();
//     _locationData = await location.getLocation();
//   }

//   _startLocationTimer() {
//     // Start the timer to capture location every second
//     _locationTimer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
//       _captureLocation();
//     });
//   }

//   _captureLocation() {
//     final latitude = _locationData.latitude ?? 0.0;
//     final longitude = _locationData.longitude ?? 0.0;

//     // Add location data to the list with the current second as the timestamp
//     _locationList.add([_currentSecond, latitude, longitude]);

//     // Increment the current second for the next timestamp
//     _currentSecond++;
//   }

//   _recordVideo() async {
//     if (_isRecording) {
//       final file = await _cameraController.stopVideoRecording();
//       setState(() => _isRecording = false);

//       // Stop the location timer when recording stops
//       _locationTimer.cancel();

//       // Save location data as CSV
//       final csvData = _convertToCsv(_locationList);

//       // Upload the video to Firebase Storage in the 'video' subfolder
//       try {
//         final videoRef = firebase_storage.FirebaseStorage.instance
//             .ref()
//             .child('video/${DateTime.now().millisecondsSinceEpoch}.mp4');

//         final locationRef = firebase_storage.FirebaseStorage.instance
//             .ref()
//             .child('location/${DateTime.now().millisecondsSinceEpoch}.csv');

//         await videoRef.putFile(File(file.path));
//         await locationRef.putString(csvData);

//         final videoDownloadUrl = await videoRef.getDownloadURL();
//         final locationDownloadUrl = await locationRef.getDownloadURL();

//         // Navigate to the video page with the download URLs
//         final route = MaterialPageRoute(
//           fullscreenDialog: true,
//           builder: (_) => VideoPage(
//             videoFilePath: videoDownloadUrl,
//             locationFilePath: locationDownloadUrl,
//             filePath: file.path,
//           ),
//         );

//         Navigator.push(context, route);
//       } catch (e) {
//         print('Error uploading video and location data: $e');
//         // Handle the error, show a snackbar or display an error message
//         // based on your application's requirements.
//       }
//     } else {
//       // Start the location timer when recording starts
//       _startLocationTimer();

//       await _cameraController.prepareForVideoRecording();
//       await _cameraController.startVideoRecording();
//       setState(() => _isRecording = true);
//     }
//   }

//   String _convertToCsv(List<List<dynamic>> data) {
//     final List<String> csvRows = [];

//     // Add header row
//     csvRows.add('Timestamp,Latitude,Longitude');

//     // Add data rows
//     for (final row in data) {
//       csvRows.add(row.join(','));
//     }

//     return csvRows.join('\n');
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Container(
//         color: Colors.white,
//         child: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     } else {
//       return Center(
//         child: Stack(
//           alignment: Alignment.bottomCenter,
//           children: [
//             CameraPreview(_cameraController),
//             Padding(
//               padding: const EdgeInsets.all(25),
//               child: FloatingActionButton(
//                 backgroundColor: Colors.red,
//                 child: Icon(_isRecording ? Icons.stop : Icons.circle),
//                 onPressed: () => _recordVideo(),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//   }
// }
