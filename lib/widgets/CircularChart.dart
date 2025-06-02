import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../colors/app_colors.dart';
import '../services/firebase/firestore.dart';

class CircularChart extends StatefulWidget {
  const CircularChart({super.key, required this.userId});

  final String userId;

  @override
  State<CircularChart> createState() => _CircularChartState();
}

class _CircularChartState extends State<CircularChart> {
  final FirestoreService _firestoreService = FirestoreService();
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsStream(isDarkMode),
        ],
      ),
    );
  }


  Widget _buildStatisticsStream(bool isDarkMode) {
    return StreamBuilder<double>(
      stream: _firestoreService.streamTotalDepenses(widget.userId),
      builder: (context, depensesSnapshot) {
        if (depensesSnapshot.hasError) {
          return Center(child: Text('Erreur de chargement des dépenses'));
        }

        return StreamBuilder<double>(
          stream: _firestoreService.streamTotalRevenus(widget.userId),
          builder: (context, revenusSnapshot) {
            if (revenusSnapshot.hasError) {
              return Center(child: Text('Erreur de chargement des revenus'));
            }

            return StreamBuilder<double>(
              stream: _firestoreService.streamTotalEpargnes(widget.userId),
              builder: (context, epargnesSnapshot) {
                if (epargnesSnapshot.hasError) {
                  return Center(child: Text('Erreur de chargement des épargnes'));
                }

                final totalDepenses = depensesSnapshot.data ?? 0.0;
                final totalRevenus = revenusSnapshot.data ?? 0.0;
                final totalEpargnes = epargnesSnapshot.data ?? 0.0;

                if (totalDepenses == 0.0 && totalRevenus == 0.0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: 'Aucune statistique disponible',
                          child: Image.asset(
                            'assets/noStatisticsImage.png',
                            width: 200,
                            height: 200,
                            color: isDarkMode ? AppColors.darkIconColor : null,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.error,
                                size: 50,
                                color: isDarkMode ? AppColors.darkErrorColor : AppColors.errorColor,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Ajoutez des transactions pour voir vos statistiques !",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return _buildChartAndSummary(totalDepenses, totalRevenus, totalEpargnes, isDarkMode);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChartAndSummary(double totalDepenses, double totalRevenus, double totalEpargnes, bool isDarkMode) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 60,
              sections: showingSections(totalDepenses, totalRevenus, isDarkMode),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegend(isDarkMode),
        const SizedBox(height: 20),
        _buildMonthlySummary(totalDepenses, totalRevenus, totalEpargnes, isDarkMode),
      ],
    );
  }

  List<PieChartSectionData> showingSections(double depenses, double revenus, bool isDarkMode) {
    final total = depenses + revenus;

    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final double radius = isTouched ? 30 : 25;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.red.shade400,
            value: depenses,
            title: total > 0 ? '${(depenses / total * 100).toStringAsFixed(1)}%' : '0%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextColor : Colors.black,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.green.shade400,
            value: revenus,
            title: total > 0 ? '${(revenus / total * 100).toStringAsFixed(1)}%' : '0%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextColor : Colors.black,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegend(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Dépenses', Colors.red.shade400, isDarkMode),
        _buildLegendItem('Revenus', Colors.green.shade400, isDarkMode),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextColor : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary(double depenses, double revenus, double epargnes, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mois de ${_getCurrentMonth()} ${DateTime.now().year}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextColor : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            _buildSummaryItem('Dépenses totales', depenses, Colors.red.shade400, isDarkMode),
            _buildSummaryItem('Revenus totaux', revenus, Colors.green.shade400, isDarkMode),
            _buildSummaryItem('Épargnes totales', epargnes, Colors.blue.shade400, isDarkMode),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkTextColor : Colors.black,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} FCFA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentMonth() {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[DateTime.now().month - 1];
  }
}