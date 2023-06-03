import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreeen extends StatefulWidget {
  const HomeScreeen({super.key});

  @override
  State<HomeScreeen> createState() => _HomeScreeenState();
}

class _HomeScreeenState extends State<HomeScreeen> {
  final LatLng _position = const LatLng(16.109900, 120.546461);
  final Set<Marker> _markers = <Marker>{};

  late GoogleMapController _mapController;

  void savePlace(String markerId, String description) {
    FirebaseFirestore.instance.collection('favorite_places').doc(markerId).set({
      'description': description,
      'latitude': _markers
          .firstWhere((marker) => marker.markerId.value == markerId)
          .position
          .latitude,
      'longitude': _markers
          .firstWhere((marker) => marker.markerId.value == markerId)
          .position
          .longitude,
    }).then((value) {
      EasyLoading.showSuccess("Successfully Added to your favorite place");
      loadFavoritePlaces();
    }).catchError((error) {
      EasyLoading.showError("Failed to save this place to your favorite");
    });
  }

  void deletePlace(String markerId) {
    FirebaseFirestore.instance
        .collection('favorite_places')
        .doc(markerId)
        .delete()
        .then((value) {
      EasyLoading.showSuccess('Successfully Deleted');
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == markerId);
      });
    }).catchError((error) {
      EasyLoading.showError("Failed to delete this place to your favorite");
    });
  }

  void loadFavoritePlaces() {
    FirebaseFirestore.instance
        .collection('favorite_places')
        .get()
        .then((querySnapshot) {
      // ignore: avoid_function_literals_in_foreach_calls
      querySnapshot.docs.forEach((doc) {
        if (doc.exists) {
          Map<String, dynamic>? data = doc.data();
          if (data.containsKey('latitude') &&
              data.containsKey('longitude') &&
              data.containsKey('description')) {
            double latitude = data['latitude'];
            double longitude = data['longitude'];
            String markerId = doc.id;
            String description = data['description'];

            setState(() {
              _markers.add(Marker(
                markerId: MarkerId(markerId),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: '\u{1F5D1} $description',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Place'),
                          content: const Text(
                              'Are you sure you want to delete this marker pointed to you favorite place?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                deletePlace(markerId);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                icon: BitmapDescriptor.defaultMarker,
                onTap: () {
                  // Handle marker tap event if needed
                },
              ));
            });
          } else {
            EasyLoading.showInfo(
                "It seems that there is missing data to be fetched");
          }
        }
      });
    }).catchError((error) {
      EasyLoading.showInfo("Failed to load favorite places");
    });
  }

  @override
  void initState() {
    super.initState();
    loadFavoritePlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Place"),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(target: _position, zoom: 13),
        onTap: (pos) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String description = '';

              return AlertDialog(
                title: const Text('Enter Description'),
                content: TextField(
                  onChanged: (value) {
                    description = value;
                  },
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (description.isNotEmpty) {
                        savePlace(
                            '${pos.latitude + pos.longitude}', description);
                        setState(() {
                          _markers.add(
                            Marker(
                              markerId:
                                  MarkerId('${pos.latitude + pos.longitude}'),
                              position: pos,
                            ),
                          );
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          Navigator.of(context).pop();
                        });
                      },
                      child: Text("Cancel"))
                ],
              );
            },
          );
          setState(() {
            _markers.add(Marker(
              markerId: MarkerId('${pos.latitude + pos.longitude}'),
              position: pos,
            ));
          });

          CameraPosition cameraPosition = CameraPosition(target: pos, zoom: 15);
          _mapController
              .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        },
        markers: _markers,
      ),
    );
  }
}
