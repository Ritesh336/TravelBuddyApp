import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/attraction.dart';
import '../../models/trip.dart';
import '../../services/places_service.dart';
import 'attraction_details_screen.dart';

class AttractionsMapScreen extends StatefulWidget {
  final Trip trip;
  final double initialLatitude;
  final double initialLongitude;

  const AttractionsMapScreen({
    super.key,
    required this.trip,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  _AttractionsMapScreenState createState() => _AttractionsMapScreenState();
}

class _AttractionsMapScreenState extends State<AttractionsMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Attraction> _attractions = [];
  bool _isLoading = false;
  String _selectedType = 'tourist_attraction';
  final Map<String, String> _placeTypes = {
    'tourist_attraction': 'Tourist Attractions',
    'restaurant': 'Restaurants',
    'hotel': 'Hotels',
    'museum': 'Museums',
    'shopping_mall': 'Shopping',
    'bar': 'Bars & Nightlife',
  };

  @override
  void initState() {
    super.initState();
    _searchNearbyPlaces();
  }

  Future<void> _searchNearbyPlaces() async {
    setState(() {
      _isLoading = true;
      _markers = {};
    });

    try {
      final attractions = await PlacesService.searchNearbyPlaces(
        latitude: widget.initialLatitude,
        longitude: widget.initialLongitude,
        type: _selectedType,
      );
      
      final markers = <Marker>{};
      
      for (var i = 0; i < attractions.length; i++) {
        final attraction = attractions[i];
        
        markers.add(
          Marker(
            markerId: MarkerId(attraction.id),
            position: LatLng(attraction.latitude, attraction.longitude),
            infoWindow: InfoWindow(
              title: attraction.name,
              snippet: attraction.address,
              onTap: () => _showAttractionDetails(attraction),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(attraction.types),
            ),
          ),
        );
      }
      
      setState(() {
        _attractions = attractions;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attractions: $e')),
      );
    }
  }

  double _getMarkerColor(List<String> types) {
    if (types.contains('restaurant')) {
      return BitmapDescriptor.hueRed;
    } else if (types.contains('lodging') || types.contains('hotel')) {
      return BitmapDescriptor.hueBlue;
    } else if (types.contains('museum')) {
      return BitmapDescriptor.hueViolet;
    } else if (types.contains('shopping_mall') || types.contains('store')) {
      return BitmapDescriptor.hueYellow;
    } else if (types.contains('bar') || types.contains('night_club')) {
      return BitmapDescriptor.hueMagenta;
    } else {
      return BitmapDescriptor.hueGreen;
    }
  }

  void _showAttractionDetails(Attraction attraction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttractionDetailsScreen(
          attraction: attraction,
          trip: widget.trip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore ${_placeTypes[_selectedType] ?? 'Places'}'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.initialLatitude,
                widget.initialLongitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          
          // Place type filter
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list),
                  items: _placeTypes.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedType) {
                      setState(() {
                        _selectedType = value;
                      });
                      _searchNearbyPlaces();
                    }
                  },
                ),
              ),
            ),
          ),
          
          // Attractions list
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Nearby ${_placeTypes[_selectedType] ?? 'Places'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _attractions.isEmpty
                        ? const Center(
                            child: Text('No places found nearby'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            scrollDirection: Axis.horizontal,
                            itemCount: _attractions.length,
                            itemBuilder: (context, index) {
                              final attraction = _attractions[index];
                              
                              return GestureDetector(
                                onTap: () {
                                  // Center map on attraction
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLng(
                                      LatLng(
                                        attraction.latitude,
                                        attraction.longitude,
                                      ),
                                    ),
                                  );
                                  
                                  // Show attraction details
                                  _showAttractionDetails(attraction);
                                },
                                child: Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Attraction image
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: attraction.photoReference.isNotEmpty
                                            ? Image.network(
                                                PlacesService.getPhotoUrl(
                                                  attraction.photoReference,
                                                ),
                                                height: 100,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    height: 100,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.white,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                      
                                      // Attraction details
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              attraction.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            if (attraction.rating > 0) ...[
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    attraction.rating.toString(),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            if (attraction.openingHours != null)
                                              Text(
                                                attraction.openingHours!,
                                                style: TextStyle(
                                                  color: attraction.openingHours ==
                                                          'Open now'
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}