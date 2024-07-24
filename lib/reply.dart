// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart' as locator;
// import 'package:geocoding/geocoding.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'OSM Flutter',
//       home: DestinationPage(),
//     );
//   }
// }

// class DestinationPage extends StatefulWidget {
//   @override
//   _DestinationPageState createState() => _DestinationPageState();
// }

// class _DestinationPageState extends State<DestinationPage> {
//   LatLng _currentLocation =
//       LatLng(37.7749, -122.4194); // Default location (San Francisco, CA)
//   LatLng _destination =
//       LatLng(37.7749, -122.4194); // Default destination coordinates

//   TextEditingController _destinationController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     locator.Location location = locator.Location();
//     try {
//       bool serviceEnabled = await location.serviceEnabled();
//       if (!serviceEnabled) {
//         serviceEnabled = await location.requestService();
//         if (!serviceEnabled) {
//           // Handle the case where the user did not enable the location service
//           return;
//         }
//       }

//       locator.LocationData currentLocation = await location.getLocation();
//       setState(() {
//         _currentLocation =
//             LatLng(currentLocation.latitude!, currentLocation.longitude!);
//       });
//     } catch (e) {
//       print("Error getting location: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Choose Destination'),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           TextField(
//             controller: _destinationController,
//             decoration: InputDecoration(
//               labelText: 'Enter Destination',
//             ),
//             onTap: () {
//               // Optionally, you can add logic here when the text field is tapped.
//               // For example, clear the text field if it contains default values.
//             },
//             onEditingComplete: () {
//               _setDestinationFromInput();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _setDestinationFromInput() async {
//     String destination = _destinationController.text;

//     // Use geocoding to convert the destination to coordinates
//     List<Location> locations = await locationFromAddress(destination);
//     if (locations.isNotEmpty) {
//       setState(() {
//         _destination = LatLng(
//           locations[0].latitude,
//           locations[0].longitude,
//         );
//       });

//       // Navigate to the map screen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => _buildMapScreen(),
//         ),
//       );
//     } else {
//       // Handle case where location is not found
//       print('Location not found for: $destination');
//     }
//   }

//   Widget _buildMapScreen() {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('OpenStreetMap in Flutter'),
//       ),
//       body: _currentLocation != null
//           ? FlutterMap(
//               options: MapOptions(
//                 center: LatLng(
//                   _currentLocation.latitude!,
//                   _currentLocation.longitude!,
//                 ),
//                 zoom: 13.0,
//               ),
//               layers: [
//                 TileLayerOptions(
//                   urlTemplate:
//                       "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//                   subdomains: ['a', 'b', 'c'],
//                 ),
//                 PolylineLayerOptions(
//                   polylines: [
//                     Polyline(
//                       points: [
//                         LatLng(
//                           _currentLocation.latitude!,
//                           _currentLocation.longitude!,
//                         ),
//                         _destination,
//                       ],
//                       strokeWidth: 4.0,
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//                 MarkerLayerOptions(
//                   markers: [
//                     Marker(
//                       width: 30.0,
//                       height: 30.0,
//                       point: LatLng(
//                         _currentLocation.latitude!,
//                         _currentLocation.longitude!,
//                       ),
//                       builder: (ctx) => Container(
//                         child: Icon(
//                           Icons.location_on,
//                           color: Colors.red,
//                         ),
//                       ),
//                     ),
//                     Marker(
//                       width: 30.0,
//                       height: 30.0,
//                       point: _destination,
//                       builder: (ctx) => Container(
//                         child: Icon(
//                           Icons.flag,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     'Destination: ${_getDestinationAddress()}',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           : Center(
//               child: CircularProgressIndicator(),
//             ),
//     );
//   }

//   String _getDestinationAddress() {
//     // Use geocoding to get the destination address
//     return 'Destination Address'; // Replace with actual logic to get the address
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart' as locator;
// import 'package:geocoding/geocoding.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'OSM Flutter',
//       initialRoute: '/',
//       routes: {
//         '/': (context) => DestinationPage(),
//       },
//     );
//   }
// }

// class DestinationPage extends StatefulWidget {
//   @override
//   _DestinationPageState createState() => _DestinationPageState();
// }

// class _DestinationPageState extends State<DestinationPage> {
//   LatLng _currentLocation =
//       LatLng(37.7749, -122.4194); // Default location (San Francisco, CA)
//   LatLng _destination =
//       LatLng(37.7749, -122.4194); // Default destination coordinates

//   TextEditingController _destinationController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     locator.Location location = locator.Location();
//     try {
//       bool serviceEnabled = await location.serviceEnabled();
//       if (!serviceEnabled) {
//         serviceEnabled = await location.requestService();
//         if (!serviceEnabled) {
//           // Handle the case where the user did not enable the location service
//           return;
//         }
//       }

//       locator.LocationData currentLocation = await location.getLocation();
//       setState(() {
//         _currentLocation =
//             LatLng(currentLocation.latitude!, currentLocation.longitude!);
//       });
//     } catch (e) {
//       print("Error getting location: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Choose Destination'),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           TextField(
//             controller: _destinationController,
//             decoration: InputDecoration(
//               labelText: 'Enter Destination',
//             ),
//             onTap: () {
//               _setDestinationFromInput();
//             },
//             onEditingComplete: () {
//               _setDestinationFromInput();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _setDestinationFromInput() async {
//     String destination = _destinationController.text;

//     // Use geocoding to convert the destination to coordinates
//     List<Location> locations = await locationFromAddress(destination);
//     if (locations.isNotEmpty) {
//       setState(() {
//         _destination = LatLng(
//           locations[0].latitude,
//           locations[0].longitude,
//         );
//       });

//       // Navigate to the map screen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MyMap(destination: _destination),
//         ),
//       );
//     } else {
//       // Handle case where location is not found
//       print('Location not found for: $destination');
//     }
//   }
// }

// class MyMap extends StatefulWidget {
//   final LatLng destination;

//   MyMap({required this.destination});

//   @override
//   _MyMapState createState() => _MyMapState();
// }

// class _MyMapState extends State<MyMap> {
//   locator.LocationData? _currentLocation;
//   String _destinationAddress = '';

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//     _getDestinationAddress();
//   }

//   Future<void> _getCurrentLocation() async {
//     locator.Location location = locator.Location();
//     try {
//       bool serviceEnabled = await location.serviceEnabled();
//       if (!serviceEnabled) {
//         serviceEnabled = await location.requestService();
//         if (!serviceEnabled) {
//           // Handle the case where the user did not enable the location service
//           return;
//         }
//       }

//       _currentLocation = await location.getLocation();
//       setState(() {});
//     } catch (e) {
//       print("Error getting location: $e");
//     }
//   }

//   Future<void> _getDestinationAddress() async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         widget.destination.latitude,
//         widget.destination.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         _destinationAddress = placemarks[0].name ?? '';
//         setState(() {});
//       }
//     } catch (e) {
//       print("Error getting destination address: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('OpenStreetMap in Flutter'),
//       ),
//       body: _currentLocation != null
//           ? FlutterMap(
//               options: MapOptions(
//                 center: LatLng(
//                   _currentLocation!.latitude!,
//                   _currentLocation!.longitude!,
//                 ),
//                 zoom: 13.0,
//               ),
//               layers: [
//                 TileLayerOptions(
//                   urlTemplate:
//                       "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//                   subdomains: ['a', 'b', 'c'],
//                 ),
//                 PolylineLayerOptions(
//                   polylines: [
//                     Polyline(
//                       points: [
//                         LatLng(
//                           _currentLocation!.latitude!,
//                           _currentLocation!.longitude!,
//                         ),
//                         widget.destination,
//                       ],
//                       strokeWidth: 4.0,
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//                 MarkerLayerOptions(
//                   markers: [
//                     Marker(
//                       width: 30.0,
//                       height: 30.0,
//                       point: LatLng(
//                         _currentLocation!.latitude!,
//                         _currentLocation!.longitude!,
//                       ),
//                       builder: (ctx) => Container(
//                         child: Icon(
//                           Icons.location_on,
//                           color: Colors.red,
//                         ),
//                       ),
//                     ),
//                     Marker(
//                       width: 30.0,
//                       height: 30.0,
//                       point: widget.destination,
//                       builder: (ctx) => Container(
//                         child: Icon(
//                           Icons.flag,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     'Destination: $_destinationAddress',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           : Center(
//               child: CircularProgressIndicator(),
//             ),
//     );
//   }
// }
