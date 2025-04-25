import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_health_companion/database.dart';
import 'dashboard.dart';

class ViewProgressPage extends StatefulWidget {
  final int userId;

  ViewProgressPage({required this.userId});

  @override
  _ViewProgressPageState createState() => _ViewProgressPageState();
}

class _ViewProgressPageState extends State<ViewProgressPage> {
  List<Map<String, dynamic>> _medicationLogs = [];
  bool _isLoading = true;
  int _selectedTimeFrame = 0; // 0: 24 hours, 1: 7 days, 2: 30 days

  @override
  void initState() {
    super.initState();
    _fetchMedicationLogs();
  }

  Future<void> _fetchMedicationLogs() async {
    try {
      DateTime startTime;
      switch (_selectedTimeFrame) {
        case 1:
          startTime = DateTime.now().subtract(Duration(days: 7));
          break;
        case 2:
          startTime = DateTime.now().subtract(Duration(days: 30));
          break;
        case 0:
        default:
          startTime = DateTime.now().subtract(Duration(hours: 24));
          break;
      }
      final logs = await DatabaseHelper.instance.getMedicationLogsWithDiseases(widget.userId, startTime);
      print('Fetched ${logs.length} medication logs: $logs');
      setState(() {
        _medicationLogs = logs;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching medication logs: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching medication logs')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, Map<String, int>> _aggregateMedicationData() {
    final Map<String, Map<String, int>> diseaseStats = {};
    for (var log in _medicationLogs) {
      final disease = log['disease_name'] as String;
      final taken = log['taken'] == 1;
      if (!diseaseStats.containsKey(disease)) {
        diseaseStats[disease] = {'taken': 0, 'missed': 0};
      }
      if (taken) {
        diseaseStats[disease]!['taken'] = diseaseStats[disease]!['taken']! + 1;
      } else {
        diseaseStats[disease]!['missed'] = diseaseStats[disease]!['missed']! + 1;
      }
      print('Aggregating for $disease: taken=${diseaseStats[disease]!['taken']}, missed=${diseaseStats[disease]!['missed']}');
    }
    print('Final disease stats: $diseaseStats');
    return diseaseStats;
  }

  Widget _buildHistogram() {
    final diseaseStats = _aggregateMedicationData();
    final timeFrameLabel = _selectedTimeFrame == 1
        ? 'Last 7 Days'
        : _selectedTimeFrame == 2
            ? 'Last 30 Days'
            : 'Last 24 Hours';

    if (diseaseStats.isEmpty) {
      return Center(
        child: Text(
          'No medication logs found for the $timeFrameLabel.',
          style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final diseases = diseaseStats.keys.toList();
    final maxY = diseaseStats.values.fold<double>(
      0,
      (max, stats) => [
        max,
        stats['taken']!.toDouble(),
        stats['missed']!.toDouble(),
      ].reduce((a, b) => a > b ? a : b),
    ).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          Text(
            'Medication Adherence ($timeFrameLabel)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final disease = diseases[groupIndex];
                      final status = rodIndex == 0 ? 'Taken' : 'Missed';
                      return BarTooltipItem(
                        '$status: ${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < diseases.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              diseases[index],
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  diseases.length,
                  (index) {
                    final stats = diseaseStats[diseases[index]]!;
                    print('Rendering bars for ${diseases[index]}: taken=${stats['taken']}, missed=${stats['missed']}');
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stats['taken']!.toDouble(),
                          color: Colors.green.shade600,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: stats['missed']!.toDouble(),
                          color: Colors.red.shade600,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                      showingTooltipIndicators: [0, 1],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(color: Colors.green.shade600, label: 'Taken'),
              const SizedBox(width: 16),
              _buildLegend(color: Colors.red.shade600, label: 'Missed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Progress'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                            child: ToggleButtons(
                              isSelected: [
                                _selectedTimeFrame == 0,
                                _selectedTimeFrame == 1,
                                _selectedTimeFrame == 2,
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _selectedTimeFrame = index;
                                  _isLoading = true;
                                });
                                _fetchMedicationLogs();
                              },
                              borderRadius: BorderRadius.circular(12),
                              selectedColor: Colors.white,
                              fillColor: Colors.blue.shade600,
                              color: Colors.blueGrey,
                              constraints: const BoxConstraints(
                                minHeight: 40.0,
                                minWidth: 100.0,
                              ),
                              children: const [
                                Text('Last 24 Hours'),
                                Text('Last 7 Days'),
                                Text('Last 30 Days'),
                              ],
                            ),
                          ),
                          _buildHistogram(),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
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
                      SnackBar(content: Text('Error: User not found')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text(
                  'Return to Dashboard',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Center(
                child: Text(
                  'Thriving Health, Vibrant Life Every Day',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}