import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final MapController mapController = MapController();

  LatLng currentLocation = const LatLng(23.2599, 77.4126);

  final Distance distance = const Distance();

  final List<Map<String, dynamic>> places = [
    {"name": "Taj Mahal", "city": "Agra", "lat": 27.1751, "lng": 78.0421},
    {"name": "Qutub Minar", "city": "Delhi", "lat": 28.5244, "lng": 77.1855},
    {"name": "Gateway of India", "city": "Mumbai", "lat": 18.9218, "lng": 72.8347},
    {"name": "Charminar", "city": "Hyderabad", "lat": 17.3616, "lng": 78.4747},
    {"name": "Jagannath Temple", "city": "Puri", "lat": 19.8047, "lng": 85.8186},
    {"name": "Mysore Palace", "city": "Mysore", "lat": 12.3051, "lng": 76.6551},
    {"name": "Hawa Mahal", "city": "Jaipur", "lat": 26.9239, "lng": 75.8267},
    {"name": "Varanasi Ghats", "city": "Varanasi", "lat": 25.3176, "lng": 82.9739},
  ];

  @override
  void initState() {
    super.initState();
    getLocation();
    startLiveTracking();
  }

  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });

    mapController.move(currentLocation, 12);
  }

  void startLiveTracking() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });

      // ✅ FIXED LINE (zoom ab reset nahi hoga)
      mapController.move(
        currentLocation,
        mapController.camera.zoom,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Tourist Satellite Map"),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              mapController.move(
                currentLocation,
                mapController.camera.zoom + 1,
              );
            },
          ),

          const SizedBox(height: 10),

          FloatingActionButton(
            child: const Icon(Icons.remove),
            onPressed: () {
              mapController.move(
                currentLocation,
                mapController.camera.zoom - 1,
              );
            },
          ),

          const SizedBox(height: 10),

          FloatingActionButton(
            child: const Icon(Icons.my_location),
            onPressed: () {
              mapController.move(currentLocation, 15);
            },
          ),
        ],
      ),

      body: FlutterMap(

        mapController: mapController,

        options: MapOptions(
          initialCenter: currentLocation,
          initialZoom: 5,
        ),

        children: [

          // 🌍 Satellite Map
          TileLayer(
            urlTemplate:
            "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
            maxZoom: 19,
          ),

          // 📍 Markers
          MarkerLayer(
            markers: [

              // 🔵 Current Location
              Marker(
                point: currentLocation,
                width: 70,
                height: 70,
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 55,
                ),
              ),

              // 🔴 Tourist Places
              ...places.map((place) {

                final LatLng point = LatLng(place["lat"], place["lng"]);
                final double km = distance(currentLocation, point) / 1000;

                return Marker(
                  point: point,
                  width: 80,
                  height: 80,

                  child: GestureDetector(
                    onTap: () {

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(place["name"]),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("City: ${place["city"]}"),
                              const SizedBox(height: 8),
                              Text("Distance: ${km.toStringAsFixed(1)} km"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            )
                          ],
                        ),
                      );
                    },

                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 35,
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          color: Colors.white,
                          child: Text(
                            place["name"],
                            style: const TextStyle(fontSize: 10),
                          ),
                        )
                      ],
                    ),
                  ),
                );

              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}