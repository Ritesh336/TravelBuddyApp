import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _apiKey = 'YOUR_CURRENCY_LAYER_API_KEY';
  static const String _baseUrl = 'http://api.apilayer.com/currency_data';

  // Get exchange rates
  static Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    final url = '$_baseUrl/live?source=$baseCurrency';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'apikey': _apiKey},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        return data['quotes'];
      } else {
        throw Exception('Currency API error: ${data['error']['info']}');
      }
    } else {
      throw Exception('Failed to fetch exchange rates: ${response.statusCode}');
    }
  }

  // Convert currency
  static Future<double> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    final rates = await getExchangeRates(fromCurrency);
    final key = '$fromCurrency$toCurrency';
    
    if (rates.containsKey(key)) {
      return amount * rates[key];
    } else {
      throw Exception('Exchange rate not available for $fromCurrency to $toCurrency');
    }
  }
}