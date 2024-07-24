import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as locator;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSM Flutter',
      home: DestinationPage(),
    );
  }
}

class DestinationPage extends StatefulWidget {
  @override
  _DestinationPageState createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  LatLng _currentLocation =
      LatLng(37.7749, -122.4194); // Default location (San Francisco, CA)
  LatLng _destination =
      LatLng(37.7749, -122.4194); // Default destination coordinates

  TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    locator.Location location = locator.Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          // Handle the case where the user did not enable the location service
          return;
        }
      }

      locator.LocationData currentLocation = await location.getLocation();
      setState(() {
        _currentLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Destination'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/dest.jpg', // Make sure to place your image in the 'assets' folder
              height: 200,
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: 300,
            child: TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Enter Destination',
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              ),
              onTap: () {
                // Optionally, you can add logic here when the text field is tapped.
                // For example, clear the text field if it contains default values.
              },
              onEditingComplete: () {
                _setDestinationFromInput();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setDestinationFromInput() async {
    String destination = _destinationController.text;

    // Use geocoding to convert the destination to coordinates
    List<Location> locations = await locationFromAddress(destination);
    if (locations.isNotEmpty) {
      setState(() {
        _destination = LatLng(
          locations[0].latitude,
          locations[0].longitude,
        );
      });

      // Fetch the route from ORS API and then navigate to the map screen
      await _fetchRouteAndNavigate();
    } else {
      // Handle case where location is not found
      print('Location not found for: $destination');
    }
  }

  Future<void> _fetchRouteAndNavigate() async {
    const apiKey = '5b3ce3597851110001cf624821c077d545ad4a15a3e9b1b67f6de7b2';
    final apiUrl = 'https://api.openrouteservice.org/v2/directions/driving-car';

    final response = await http.get(
      Uri.parse(
          '$apiUrl?api_key=$apiKey&start=${_currentLocation.longitude},${_currentLocation.latitude}&end=${_destination.longitude},${_destination.latitude}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      List<dynamic> coordinates =
          data['features'][0]['geometry']['coordinates'];

      List<LatLng> routeCoordinates =
          coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

      // Navigate to the map screen with the route coordinates
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _buildMapScreen(routeCoordinates),
        ),
      );
    } else {
      // Handle error case
      print('Failed to fetch route: ${response.statusCode}');
    }
  }

  Widget _buildMapScreen(List<LatLng> routeCoordinates) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenStreetMap in Flutter'),
      ),
      // ignore: unnecessary_null_comparison
      body: _currentLocation != null
          ? FlutterMap(
              options: MapOptions(
                center: LatLng(
                  _currentLocation.latitude,
                  _currentLocation.longitude,
                ),
                zoom: 13.0,
              ),
              layers: [
                TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                PolylineLayerOptions(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(
                          _currentLocation.latitude,
                          _currentLocation.longitude,
                        ),
                        ...routeCoordinates,
                        _destination,
                      ],
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayerOptions(
                  markers: [
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: LatLng(
                        _currentLocation.latitude,
                        _currentLocation.longitude,
                      ),
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: _destination,
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.flag,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder<String>(
                    future: _getDestinationAddress(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error getting destination address');
                      } else {
                        return Text(
                          'Destination: ${snapshot.data ?? "Unknown Address"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Future<String> _getDestinationAddress() async {
    // Use geocoding to get the destination address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      _destination.latitude,
      _destination.longitude,
    );
    if (placemarks.isNotEmpty) {
      return placemarks[0].name ?? 'Unknown Address';
    } else {
      return 'Unknown Address';
    }
  }
}
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart' as locator;
// import 'package:geocoding/geocoding.dart';
// import 'package:http/http.dart' as http;

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
//           Center(
//             child: Image.asset(
//               'assets/images/dest.jpg', // Make sure to place your image in the 'assets' folder
//               height: 200,
//             ),
//           ),
//           SizedBox(height: 20),
//           Container(
//             width: 300,
//             child: TextField(
//               controller: _destinationController,
//               decoration: InputDecoration(
//                 labelText: 'Enter Destination',
//                 contentPadding:
//                     EdgeInsets.symmetric(vertical: 20, horizontal: 10),
//               ),
//               onTap: () {
//                 // Optionally, you can add logic here when the text field is tapped.
//                 // For example, clear the text field if it contains default values.
//               },
//               onEditingComplete: () {
//                 _setDestinationFromInput();
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _setDestinationFromInput() async {
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

//       // Fetch the route from ORS API and then navigate to the map screen
//       await _fetchRouteAndNavigate();
//     } else {
//       // Handle case where location is not found
//       print('Location not found for: $destination');
//     }
//   }

//   Future<void> _fetchRouteAndNavigate() async {
//     // const apiKey = 'YOUR_API_KEY'; // Add your API key here
//     final apiUrl = 'https://api.openrouteservice.org/v2/directions/driving-car';

//     final response = await http.get(
//       Uri.parse(
//           '$apiUrl?api_key=YOUR_API_KEY&start=${_currentLocation.longitude},${_currentLocation.latitude}&end=${_destination.longitude},${_destination.latitude}'),
//     );

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);

//       List<dynamic> coordinates =
//           data['features'][0]['geometry']['coordinates'];

//       List<LatLng> routeCoordinates =
//           coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

//       // Navigate to the map screen with the route coordinates
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => _buildMapScreen(routeCoordinates),
//         ),
//       );
//     } else {
//       // Handle error case
//       print('Failed to fetch route: ${response.statusCode}');
//     }
//   }

//   Widget _buildMapScreen(List<LatLng> routeCoordinates) {
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
//                         ...routeCoordinates,
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
//                   child: FutureBuilder<String>(
//                     future: _getDestinationAddress(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return CircularProgressIndicator();
//                       } else if (snapshot.hasError) {
//                         return Text('Error getting destination address');
//                       } else {
//                         return Text(
//                           'Destination: ${snapshot.data ?? "Unknown Address"}',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         );
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             )
//           : Center(
//               child: CircularProgressIndicator(),
//             ),
//     );
//   }

//   Future<String> _getDestinationAddress() async {
//     // Use geocoding to get the destination address
//     List<Placemark> placemarks = await placemarkFromCoordinates(
//       _destination.latitude,
//       _destination.longitude,
//     );
//     if (placemarks.isNotEmpty) {
//       return placemarks[0].name ?? 'Unknown Address';
//     } else {
//       return 'Unknown Address';
//     }
//   }
// }
