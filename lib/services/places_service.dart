import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attraction.dart';

class PlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Search for nearby attractions
  static Future<List<Attraction>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String type,
    int radius = 5000,
  }) async {
    final url = '$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius&type=$type&key=$_apiKey';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final results = data['results'] as List;
        return results
            .map((place) => Attraction.fromPlacesApi(place))
            .toList();
      } else {
        throw Exception('Places API error: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch places: ${response.statusCode}');
    }
  }

  // Get place details
  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = '$_baseUrl/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number,opening_hours,website,geometry&key=$_apiKey';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Places API error: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch place details: ${response.statusCode}');
    }
  }

  // Get place photo
  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$_apiKey';
  }
}