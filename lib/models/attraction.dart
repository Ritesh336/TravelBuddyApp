class Attraction {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String photoReference;
  final List<String> types;
  final String? openingHours;
  final String? phoneNumber;
  final String? website;

  Attraction({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.photoReference,
    required this.types,
    this.openingHours,
    this.phoneNumber,
    this.website,
  });

  factory Attraction.fromPlacesApi(Map<String, dynamic> place) {
    final location = place['geometry']['location'];
    
    return Attraction(
      id: place['place_id'] ?? '',
      name: place['name'] ?? '',
      address: place['vicinity'] ?? '',
      latitude: location['lat'],
      longitude: location['lng'],
      rating: (place['rating'] ?? 0.0).toDouble(),
      photoReference: place['photos'] != null && place['photos'].isNotEmpty
          ? place['photos'][0]['photo_reference']
          : '',
      types: List<String>.from(place['types'] ?? []),
      openingHours: place['opening_hours'] != null
          ? place['opening_hours']['open_now'] != null
              ? place['opening_hours']['open_now'] ? 'Open now' : 'Closed'
              : null
          : null,
    );
  }
}