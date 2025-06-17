import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CombinedFinanceChart extends StatefulWidget {
  final String userId;
  final int selectedMonth;

  const CombinedFinanceChart({
    required this.userId,
    required this.selectedMonth,
    Key? key,
  }) : super(key: key);

  @override
  _CombinedFinanceChartState createState() => _CombinedFinanceChartState();
}

class _CombinedFinanceChartState extends State<CombinedFinanceChart> {
  late Stream<List<Map<String, dynamic>>> _expensesStream;
  late Stream<List<Map<String, dynamic>>> _savingsStream;
  late Stream<List<Map<String, dynamic>>> _revenuesStream;

  @override
  void initState() {
    super.initState();
    _expensesStream = _fetchExpensesStream();
    _savingsStream = _fetchSavingsStream();
    _revenuesStream = _fetchRevenuesStream();
  }

  @override
  void didUpdateWidget(covariant CombinedFinanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      setState(() {
        _expensesStream = _fetchExpensesStream();
        _savingsStream = _fetchSavingsStream();
        _revenuesStream = _fetchRevenuesStream();
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchExpensesStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, widget.selectedMonth, 1);
    final end = DateTime(now.year, widget.selectedMonth + 1, 1).subtract(const Duration(seconds: 1));

    return FirebaseFirestore.instance
        .collection('depenses')
        .where('userId', isEqualTo: widget.userId)
        .where('dateCreation', isGreaterThanOrEqualTo: start)
        .where('dateCreation', isLessThanOrEqualTo: end)
        .orderBy('dateCreation')
        .limit(31)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': (data['dateCreation'] as Timestamp).toDate(),
        'montant': (data['montant'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList());
  }

  Stream<List<Map<String, dynamic>>> _fetchSavingsStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, widget.selectedMonth, 1);
    final end = DateTime(now.year, widget.selectedMonth + 1, 1).subtract(const Duration(seconds: 1));

    return FirebaseFirestore.instance
        .collection('epargnes')
        .where('userId', isEqualTo: widget.userId)
        .where('dateCreation', isGreaterThanOrEqualTo: start)
        .where('dateCreation', isLessThanOrEqualTo: end)
        .orderBy('dateCreation')
        .limit(31)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': (data['dateCreation'] as Timestamp).toDate(),
        'montant': (data['montant'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList());
  }

  Stream<List<Map<String, dynamic>>> _fetchRevenuesStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, widget.selectedMonth, 1);
    final end = DateTime(now.year, widget.selectedMonth + 1, 1).subtract(const Duration(seconds: 1));

    return FirebaseFirestore.instance
        .collection('revenus')
        .where('userId', isEqualTo: widget.userId)
        .where('dateCreation', isGreaterThanOrEqualTo: start)
        .where('dateCreation', isLessThanOrEqualTo: end)
        .orderBy('dateCreation')
        .limit(31)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': (data['dateCreation'] as Timestamp).toDate(),
        'montant': (data['montant'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDarkMode ? const BorderSide(color: Colors.white, width: 1) : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finances Mensuelles',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                fontSize: screenWidth * 0.05,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: screenWidth * 0.6,
              child: StreamBuilder<List<dynamic>>(
                stream: StreamGroup.merge([
                  _expensesStream,
                  _savingsStream,
                  _revenuesStream,
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: colors.error, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Erreur de chargement',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
                          ),
                        ],
                      ),
                    );
                  }

                  final expensesData = snapshot.data?[0] as List<Map<String, dynamic>>? ?? [];
                  final savingsData = snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];
                  final revenuesData = snapshot.data?[2] as List<Map<String, dynamic>>? ?? [];

                  // Aggregate data by day
                  final Map<int, Map<String, double>> aggregatedData = {};
                  for (var data in expensesData) {
                    final day = (data['date'] as DateTime).day;
                    aggregatedData[day] = aggregatedData[day] ?? {'expenses': 0.0, 'savings': 0.0, 'revenues': 0.0};
                    aggregatedData[day]!['expenses'] = aggregatedData[day]!['expenses']! + data['montant'];
                  }
                  for (var data in savingsData) {
                    final day = (data['date'] as DateTime).day;
                    aggregatedData[day] = aggregatedData[day] ?? {'expenses': 0.0, 'savings': 0.0, 'revenues': 0.0};
                    aggregatedData[day]!['savings'] = aggregatedData[day]!['savings']! + data['montant'];
                  }
                  for (var data in revenuesData) {
                    final day = (data['date'] as DateTime).day;
                    aggregatedData[day] = aggregatedData[day] ?? {'expenses': 0.0, 'savings': 0.0, 'revenues': 0.0};
                    aggregatedData[day]!['revenues'] = aggregatedData[day]!['revenues']! + data['montant'];
                  }

                  if (aggregatedData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart, color: colors.onSurface.withOpacity(0.5), size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Aucune donnée ce mois-ci',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Find max value for y-axis
                  final maxY = aggregatedData.values.fold<double>(
                    100.0,
                        (max, data) => [
                      max,
                      data['expenses']!,
                      data['savings']!,
                      data['revenues']!,
                    ].reduce((a, b) => a > b ? a : b) * 1.2,
                  );

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      minY: 0,
                      groupsSpace: 24,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final day = aggregatedData.keys.elementAt(groupIndex);
                            final type = rodIndex == 0
                                ? 'Dépenses'
                                : rodIndex == 1
                                ? 'Épargnes'
                                : 'Revenus';
                            return BarTooltipItem(
                              '$day/${widget.selectedMonth}\n$type: ${rod.toY.toStringAsFixed(0)} FCFA',
                              TextStyle(
                                color: colors.onSurface,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  '${value.toInt()} FCFA',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < aggregatedData.length) {
                                return Text(
                                  '${aggregatedData.keys.elementAt(index)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onSurface.withOpacity(0.6),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: colors.onSurface.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: aggregatedData.entries.toList().asMap().entries.map((entry) {
                        final day = entry.value.key;
                        final data = entry.value.value;
                        return BarChartGroupData(
                          x: entry.key,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: data['expenses']!,
                              color: Colors.pink.shade100,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: colors.surfaceVariant,
                              ),
                            ),
                            BarChartRodData(
                              toY: data['savings']!,
                              color: Colors.blue.shade100,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: colors.surfaceVariant,
                              ),
                            ),
                            BarChartRodData(
                              toY: data['revenues']!,
                              color: Colors.green.shade100,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: colors.surfaceVariant,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Dépenses', Colors.pink.shade100, theme),
                const SizedBox(width: 16),
                _buildLegendItem('Épargnes', Colors.blue.shade100, theme),
                const SizedBox(width: 16),
                _buildLegendItem('Revenus', Colors.green.shade100, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// Helper class to merge streams (since StreamGroup is not part of the standard Flutter/Dart libraries)
class StreamGroup {
  static Stream<List<T>> merge<T>(List<Stream<T>> streams) {
    return Stream<List<T>>.multi((controller) {
      final values = List<T?>.filled(streams.length, null);
      var completed = 0;

      for (var i = 0; i < streams.length; i++) {
        streams[i].listen(
              (value) {
            values[i] = value;
            controller.add(values.cast<T>());
          },
          onError: controller.addError,
          onDone: () {
            if (++completed == streams.length) {
              controller.close();
            }
          },
        );
      }
    });
  }
}