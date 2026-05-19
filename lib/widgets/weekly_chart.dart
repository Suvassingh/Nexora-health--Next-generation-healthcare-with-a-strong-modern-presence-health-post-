import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_constants.dart';
class WeeklyChart extends StatelessWidget {
  final List<int> dailyCounts;

  const WeeklyChart({super.key, required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This week',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          days[v.toInt()],
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (i) => BarChartGroupData(
                    x: i,
                    barRods: [BarChartRodData(
                      toY: dailyCounts[i].toDouble(),
                      color: i == DateTime.now().weekday - 1
                          ? AppConstants.primaryColor
                          : const Color(0xFFE0E0E0),
                      width: 18,
                      borderRadius: BorderRadius.circular(6),
                    )],
                  )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}