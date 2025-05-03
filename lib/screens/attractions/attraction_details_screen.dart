import 'package:flutter/material.dart'hide TimeOfDay;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/attraction.dart';
import '../../models/trip.dart';
import '../../models/trip_data.dart';
import '../../services/places_service.dart';
import '../../services/currency_service.dart';

class AttractionDetailsScreen extends StatefulWidget {
  final Attraction attraction;
  final Trip trip;

  const AttractionDetailsScreen({
    super.key,
    required this.attraction,
    required this.trip,
  });

  @override
  _AttractionDetailsScreenState createState() => _AttractionDetailsScreenState();
}

class _AttractionDetailsScreenState extends State<AttractionDetailsScreen> {
  bool _isLoading = true;
  bool _isAddingToTrip = false;
  Map<String, dynamic>? _placeDetails;
  final _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  double? _convertedAmount;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _loadPlaceDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaceDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final details = await PlacesService.getPlaceDetails(widget.attraction.id);
      
      setState(() {
        _placeDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading details: $e')),
      );
    }
  }

  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) return;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;
    
    setState(() {
      _isConverting = true;
    });
    
    try {
      final converted = await CurrencyService.convertCurrency(
        amount,
        _selectedCurrency,
        'USD',
      );
      
      setState(() {
        _convertedAmount = converted;
        _isConverting = false;
      });
    } catch (e) {
      setState(() {
        _isConverting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error converting currency: $e')),
      );
    }
  }

  Future<void> _addToTrip() async {
    setState(() {
      _isAddingToTrip = true;
    });

    try {
      // Select day
      final day = await _selectDay(context);
      if (day == null) {
        setState(() {
          _isAddingToTrip = false;
        });
        return;
      }
      
      // Create activity from attraction
      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: widget.attraction.name,
        date: day.date,
        startTime: TimeOfDay(hour: 10, minute: 0),
        endTime: TimeOfDay(hour: 12, minute: 0),
        location: widget.attraction.address,
        cost: 0.0,
        latitude: widget.attraction.latitude,
        longitude: widget.attraction.longitude,
      );
      
      // Add activity to trip
      Provider.of<TripData>(context, listen: false).addDayActivity(
        widget.trip.id,
        day.id,
        activity,
      );
      
      setState(() {
        _isAddingToTrip = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.attraction.name} added to your trip!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isAddingToTrip = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to trip: $e')),
      );
    }
  }

  Future<Day?> _selectDay(BuildContext context) async {
    return showDialog<Day>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Day'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.trip.days.length,
              itemBuilder: (context, index) {
                final day = widget.trip.days[index];
                return ListTile(
                  title: Text(day.title),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(day.date)),
                  onTap: () {
                    Navigator.pop(context, day);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App bar with image
                SliverAppBar(
                  expandedHeight: 200.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.attraction.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Color.fromARGB(150, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                    background: widget.attraction.photoReference.isNotEmpty
                        ? Image.network(
                            PlacesService.getPhotoUrl(
                              widget.attraction.photoReference,
                              maxWidth: 800,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Theme.of(context).primaryColor,
                            child: Icon(
                              Icons.place,
                              color: Colors.white.withOpacity(0.5),
                              size: 80,
                            ),
                          ),
                  ),
                ),
                
                // Attraction details
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating
                        if (widget.attraction.rating > 0)
                          Row(
                            children: [
                              ...List.generate(
                                widget.attraction.rating.round(),
                                (index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                              ...List.generate(
                                5 - widget.attraction.rating.round(),
                                (index) => Icon(
                                  Icons.star_border,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.attraction.rating.toString(),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        
                        // Address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.attraction.address,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        
                        // Opening hours
                        if (_placeDetails != null &&
                            _placeDetails!['opening_hours'] != null) ...[
                          const Text(
                            'Opening Hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_placeDetails!['opening_hours']['weekday_text'] != null)
                            ...(_placeDetails!['opening_hours']['weekday_text'] as List)
                                .map((day) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(day),
                                    ))
                                .toList()
                          else
                            Text(
                              widget.attraction.openingHours ?? 'Hours not available',
                              style: TextStyle(
                                color: widget.attraction.openingHours == 'Open now'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          const Divider(height: 32),
                        ],
                        
                        // Contact info
                        if (_placeDetails != null) ...[
                          const Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_placeDetails!['formatted_phone_number'] != null)
                            Row(
                              children: [
                                const Icon(Icons.phone),
                                const SizedBox(width: 8),
                                Text(_placeDetails!['formatted_phone_number']),
                              ],
                            ),
                          const SizedBox(height: 8),
                          if (_placeDetails!['website'] != null)
                            Row(
                              children: [
                                const Icon(Icons.language),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _placeDetails!['website'],
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const Divider(height: 32),
                        ],
                        
                        // Currency converter
                        const Text(
                          'Currency Converter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Amount input
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Currency dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCurrency,
                                  items: _currencies.map((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency,
                                      child: Text(currency),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCurrency = value;
                                        _convertedAmount = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isConverting ? null : _convertCurrency,
                                child: _isConverting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Convert to USD'),
                              ),
                            ),
                          ],
                        ),
                        if (_convertedAmount != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_amountController.text} $_selectedCurrency = ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${_convertedAmount!.toStringAsFixed(2)} USD',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _isAddingToTrip ? null : _addToTrip,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(12),
            ),
            child: _isAddingToTrip
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Add to Trip',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}