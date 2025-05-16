import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_health_companion/database.dart';
import 'dashboard.dart';

class HealthGuidancePage extends StatefulWidget {
  final int userId;

  HealthGuidancePage({required this.userId});

  @override
  _HealthGuidancePageState createState() => _HealthGuidancePageState();
}

class _HealthGuidancePageState extends State<HealthGuidancePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _foodItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // USDA FoodData Central API key
  static const String _apiKey = 'urOUTtjPaccTNOGLcOMNdCTetebZr38BfLJoHk0R';

  Future<void> _searchFoodItems(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a food item to search.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foodItems = [];
    });

    try {
      final url = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search?query=${Uri.encodeQueryComponent(query)}&pageSize=20&dataType=Foundation,SR%20Legacy,Branded&api_key=$_apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> foods = data['foods'] ?? [];
        final List<Map<String, dynamic>> filteredFoods = [];

        for (var food in foods) {
          final nutrients = food['foodNutrients'] ?? [];
          Map<String, dynamic> nutrientData = {
            'Protein': {'value': 0.0, 'unit': 'g'},
            'Total lipid (fat)': {'value': 0.0, 'unit': 'g'},
            'Carbohydrate, by difference': {'value': 0.0, 'unit': 'g'},
            'Energy': {'value': 0.0, 'unit': 'kcal'},
            'Fiber, total dietary': {'value': 0.0, 'unit': 'g'},
            'Sugars, total including NLEA': {'value': 0.0, 'unit': 'g'},
          };

          for (var nutrient in nutrients) {
            final name = nutrient['nutrientName'];
            if (nutrientData.containsKey(name)) {
              nutrientData[name] = {
                'value': (nutrient['value'] ?? 0.0).toDouble(),
                'unit': nutrient['unitName']?.toLowerCase() ?? 'g',
              };
            }
          }

          if (nutrientData.values.any((n) => n['value'] > 0)) {
            filteredFoods.add({
              'name': food['description'] ?? 'Unknown Food',
              'serving_size': 100.0,
              'serving_unit': 'g',
              'nutrients': nutrientData,
            });
          }
        }

        setState(() {
          _foodItems = filteredFoods;
          if (_foodItems.isEmpty) {
            _errorMessage = 'No foods with nutritional data found for "$query".';
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Guidance'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            color: Colors.grey.shade400,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      try {
                        return Image.asset(
                          'assets/images/medical_image.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            print('Asset loading error: $error\n$stackTrace');
                            return Container(
                              color: Colors.blue.shade50,
                              child: Center(child: Text('Failed to load background image')),
                            );
                          },
                        );
                      } catch (e) {
                        print('Exception loading asset: $e');
                        return Container(
                          color: Colors.blue.shade50,
                          child: Center(child: Text('Exception loading background image')),
                        );
                      }
                    },
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Search for Food Nutrition',
                            hintText: 'Enter food item (e.g., chicken, tofu)',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.search, color: Colors.blue.shade600),
                              onPressed: () => _searchFoodItems(_searchController.text),
                            ),
                          ),
                          onSubmitted: _searchFoodItems,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                if (_errorMessage != null)
                                  Center(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red, fontSize: 16),
                                    ),
                                  )
                                else if (_foodItems.isNotEmpty)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _foodItems.length,
                                    itemBuilder: (context, index) {
                                      final food = _foodItems[index];
                                      final nutrients = food['nutrients'] as Map<String, dynamic>? ?? {};
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                food['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Per ${food['serving_size']} ${food['serving_unit']}:',
                                                style: const TextStyle(color: Colors.blueGrey),
                                              ),
                                              const SizedBox(height: 8),
                                              if (nutrients.isNotEmpty)
                                                ...nutrients.entries.map((entry) {
                                                  final nutrient = entry.value;
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                    child: Text(
                                                      '${entry.key}: ${nutrient['value'].toStringAsFixed(1)} ${nutrient['unit']}',
                                                      style: const TextStyle(color: Colors.blueGrey),
                                                    ),
                                                  );
                                                }).toList()
                                              else
                                                const Text(
                                                  'No nutritional data available',
                                                  style: TextStyle(color: Colors.blueGrey),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  const Center(
                                    child: Text(
                                      'Search for a food item to see nutritional content.',
                                      style: TextStyle(color: Colors.black87, fontSize: 16),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () async {
                                    final user = await DatabaseHelper.instance.getUserById(widget.userId);
                                    if (user != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DashboardPage(user: user),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Error: User not found')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text(
                                    'Return to Dashboard',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}