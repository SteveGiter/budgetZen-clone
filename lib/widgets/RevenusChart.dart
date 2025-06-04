import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RevenusChart extends StatefulWidget {
  final String userId;
  final int selectedMonth;

  const RevenusChart({
    required this.userId,
    required this.selectedMonth,
    Key? key,
  }) : super(key: key);

  @override
  _RevenusChartState createState() => _RevenusChartState();
}

class _RevenusChartState extends State<RevenusChart> {
  late Stream<List<Map<String, dynamic>>> _revenusStream;

  @override
  void initState() {
    super.initState();
    _revenusStream = _fetchRevenusStream();
  }

  @override
  void didUpdateWidget(covariant RevenusChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      setState(() {
        _revenusStream = _fetchRevenusStream();
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchRevenusStream() {
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
        side: isDarkMode
            ? const BorderSide(color: Colors.white, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenus Mensuels',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                fontSize: screenWidth * 0.05, // Responsive font size
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: screenWidth * 0.6, // Responsive height
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _revenusStream,
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

                  final revenusData = snapshot.data ?? [];
                  if (revenusData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart, color: colors.onSurface.withOpacity(0.5), size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun revenu ce mois-ci',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: revenusData.isNotEmpty
                          ? revenusData.map((e) => e['montant']).reduce((a, b) => a > b ? a : b) * 1.2
                          : 100.0,
                      minY: 0,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final date = revenusData[groupIndex]['date'] as DateTime;
                            return BarTooltipItem(
                              '${date.day}/${date.month}\n${rod.toY.toStringAsFixed(0)} FCFA',
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
                              if (index >= 0 && index < revenusData.length) {
                                final date = revenusData[index]['date'] as DateTime;
                                return Text(
                                  '${date.day}',
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
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: revenusData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value['montant'],
                              color: Colors.green.shade100,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: revenusData.isNotEmpty
                                    ? revenusData.map((e) => e['montant']).reduce((a, b) => a > b ? a : b) * 1.2
                                    : 100.0,
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
          ],
        ),
      ),
    );
  }
}